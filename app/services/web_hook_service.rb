# frozen_string_literal: true

class WebHookService
  include Gitlab::Utils::StrongMemoize

  class InternalErrorResponse
    ERROR_MESSAGE = 'internal error'

    attr_reader :body, :headers, :code

    def success?
      false
    end

    def redirection?
      false
    end

    def internal_server_error?
      true
    end

    def initialize
      @headers = Gitlab::HTTP::Response::Headers.new({})
      @body = ''
      @code = ERROR_MESSAGE
    end
  end

  CustomWebHookTemplateError = Class.new(StandardError)

  REQUEST_BODY_SIZE_LIMIT = 25.megabytes
  # Response body is for UI display only. It does not make much sense to save
  # whatever the receivers throw back at us
  RESPONSE_BODY_SIZE_LIMIT = 8.kilobytes
  # The headers are for debugging purpose. They are displayed on the UI only.
  RESPONSE_HEADERS_COUNT_LIMIT = 50
  RESPONSE_HEADERS_SIZE_LIMIT = 1.kilobyte

  CUSTOM_TEMPLATE_INTERPOLATION_REGEX = /{{(.+?)}}/

  attr_accessor :hook, :data, :hook_name, :request_options
  attr_reader :uniqueness_token, :idempotency_key

  def self.hook_to_event(hook_name, hook = nil)
    return hook.class.name.titleize if hook.is_a?(SystemHook)

    hook_name.to_s.singularize.titleize
  end

  def initialize(hook, data, hook_name, uniqueness_token = nil, idempotency_key: nil, force: false)
    @hook = hook
    @data = data.to_h
    @hook_name = hook_name.to_s
    @uniqueness_token = uniqueness_token
    @idempotency_key = idempotency_key || generate_idempotency_key
    @force = force
    @request_options = {
      timeout: Gitlab.config.gitlab.webhook_timeout,
      allow_local_requests: hook.allow_local_requests?
    }
  end

  def disabled?
    !@force && !hook.executable?
  end

  def execute
    if Gitlab::SilentMode.enabled?
      log_silent_mode_enabled
      return ServiceResponse.error(message: 'Silent mode enabled')
    end

    return ServiceResponse.error(message: 'Hook disabled') if disabled?

    if rate_limit!
      log_rate_limited
      create_broadcast_message("Webhook rate limit exceeded")
      return ServiceResponse.error(message: 'Webhook rate limit exceeded')
    end

    if recursion_blocked?
      log_recursion_blocked
      create_broadcast_message("Recursive webhook blocked")
      return ServiceResponse.error(message: 'Recursive webhook blocked')
    end

    Gitlab::WebHooks::RecursionDetection.register!(hook)

    start_time = Gitlab::Metrics::System.monotonic_time

    response = if parsed_url.userinfo.blank?
                 make_request(parsed_url.to_s)
               else
                 make_request_with_auth
               end

    log_execution(
      response: response,
      execution_duration: ::Gitlab::Metrics::System.monotonic_time - start_time
    )

    ServiceResponse.success(message: response.body, payload: { http_status: response.code })
  rescue *Gitlab::HTTP::HTTP_ERRORS, CustomWebHookTemplateError, Zlib::DataError,
    Gitlab::Json::LimitedEncoder::LimitExceeded, URI::InvalidURIError => e
    execution_duration = ::Gitlab::Metrics::System.monotonic_time - start_time
    error_message = e.to_s

    # An exception raised while rendering the custom template prevents us from calling `#request_payload`
    request_data = e.instance_of?(CustomWebHookTemplateError) ? {} : request_payload

    log_execution(
      response: InternalErrorResponse.new,
      execution_duration: execution_duration,
      error_message: error_message,
      request_data: request_data
    )

    Gitlab::AppLogger.error("WebHook Error after #{execution_duration.to_i.seconds}s => #{e}")

    ServiceResponse.error(message: error_message)
  end

  def async_execute
    Gitlab::ApplicationContext.with_context(hook.application_context) do
      break log_silent_mode_enabled if Gitlab::SilentMode.enabled?

      if rate_limit!
        log_rate_limited
        create_broadcast_message("Webhook rate limit exceeded")
        break
      end

      if recursion_blocked?
        log_recursion_blocked
        create_broadcast_message("Recursive webhook blocked")
        break
      end

      params = {
        "recursion_detection_request_uuid" => Gitlab::WebHooks::RecursionDetection::UUID.instance.request_uuid,
        "idempotency_key" => idempotency_key
      }.compact

      WebHookWorker.perform_async(hook.id, data.deep_stringify_keys, hook_name.to_s, params)
    end
  end

  private

  def parsed_url
    @parsed_url ||= URI.parse(hook.interpolated_url)
  rescue WebHook::InterpolationError => e
    # Behavior-preserving fallback.
    Gitlab::ErrorTracking.track_exception(e)
    @parsed_url = URI.parse(hook.url)
  end

  def generate_idempotency_key
    SecureRandom.uuid
  end

  def make_request(url, basic_auth = false)
    Gitlab::HTTP.post(url,
      body: Gitlab::Json::LimitedEncoder.encode(request_payload, limit: REQUEST_BODY_SIZE_LIMIT),
      headers: build_custom_headers.merge(build_headers),
      verify: hook.enable_ssl_verification,
      basic_auth: basic_auth,
      max_bytes: Gitlab::CurrentSettings.max_http_response_size_limit.megabytes,
      **request_options)
  end

  def make_request_with_auth
    post_url = parsed_url.to_s.gsub("#{parsed_url.userinfo}@", '')
    basic_auth = {
      username: CGI.unescape(parsed_url.user),
      password: CGI.unescape(parsed_url.password.presence || '')
    }
    make_request(post_url, basic_auth)
  end

  def log_execution(response:, execution_duration:, error_message: nil, request_data: request_payload)
    category = response_category(response)
    log_data = {
      trigger: hook_name,
      url: hook.url,
      interpolated_url: hook.interpolated_url,
      execution_duration: execution_duration,
      request_headers: build_custom_headers(values_redacted: true).merge(build_headers),
      request_data: request_data,
      response_headers: safe_response_headers(response),
      response_body: safe_response_body(response),
      response_status: response.code,
      internal_error_message: error_message
    }

    if @force # executed as part of test - run log-execution inline.
      ::WebHooks::LogExecutionService.new(hook: hook, log_data: log_data, response_category: category).execute
    else
      queue_log_execution_with_retry(log_data, category)
    end
  end

  def queue_log_execution_with_retry(log_data, category)
    retried = false
    begin
      ::WebHooks::LogExecutionWorker.perform_async(
        hook.id, log_data.deep_stringify_keys, category.to_s, uniqueness_token.to_s
      )
    rescue Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError
      raise if retried

      # Strip request data
      log_data[:request_data] = ::WebHookLog::OVERSIZE_REQUEST_DATA
      retried = true
      retry
    end
  end

  def response_category(response)
    if response.success? || response.redirection?
      :ok
    else
      :error
    end
  end

  def build_headers
    @headers ||= begin
      headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => "GitLab/#{Gitlab::VERSION}",
        'Idempotency-Key' => idempotency_key,
        Gitlab::WebHooks::GITLAB_EVENT_HEADER => self.class.hook_to_event(hook_name, hook),
        Gitlab::WebHooks::GITLAB_UUID_HEADER => SecureRandom.uuid,
        Gitlab::WebHooks::GITLAB_INSTANCE_HEADER => Gitlab.config.gitlab.base_url
      }

      headers['X-Gitlab-Token'] = Gitlab::Utils.remove_line_breaks(hook.token) if hook.token.present?
      headers.merge!(Gitlab::WebHooks::RecursionDetection.header(hook))
    end
  end

  def build_custom_headers(values_redacted: false)
    return {} unless hook.custom_headers.present?

    return hook.custom_headers.transform_values { '[REDACTED]' } if values_redacted

    hook.custom_headers
  end

  # Make response headers more stylish
  # Net::HTTPHeader has downcased hash with arrays: { 'content-type' => ['text/html; charset=utf-8'] }
  # This method format response to capitalized hash with strings: { 'Content-Type' => 'text/html; charset=utf-8' }
  def safe_response_headers(response)
    response.headers.each_capitalized.first(RESPONSE_HEADERS_COUNT_LIMIT).to_h do |header_key, header_value|
      [enforce_utf8(header_key), string_size_limit(enforce_utf8(header_value), RESPONSE_HEADERS_SIZE_LIMIT)]
    end
  end

  def safe_response_body(response)
    return '' unless response.body

    response_body = enforce_utf8(response.body)
    string_size_limit(response_body, RESPONSE_BODY_SIZE_LIMIT)
  end

  # Increments rate-limit counter.
  # Returns true if hook should be rate-limited.
  def rate_limit!
    Gitlab::WebHooks::RateLimiter.new(hook).rate_limit!
  end

  def recursion_blocked?
    Gitlab::WebHooks::RecursionDetection.block?(hook)
  end

  def log_rate_limited
    log_auth_error('Webhook rate limit exceeded')
  end

  def log_recursion_blocked
    log_auth_error(
      'Recursive webhook blocked from executing',
      recursion_detection: ::Gitlab::WebHooks::RecursionDetection.to_log(hook)
    )
  end

  def log_silent_mode_enabled
    log_auth_error('GitLab is in silent mode')
  end

  def log_auth_error(message, params = {})
    Gitlab::AuthLogger.error(
      params.merge(
        { message: message, hook_id: hook.id, hook_type: hook.type, hook_name: hook_name },
        Gitlab::ApplicationContext.current
      )
    )
  end

  def string_size_limit(str, limit)
    str.truncate_bytes(limit)
  end

  def enforce_utf8(str)
    Gitlab::EncodingHelper.encode_utf8(str)
  end

  def request_payload
    return data unless hook.custom_webhook_template.present?

    start_time = Gitlab::Metrics::System.monotonic_time
    rendered_template = render_custom_template(hook.custom_webhook_template, data.deep_stringify_keys)
    duration = Gitlab::Metrics::System.monotonic_time - start_time

    Gitlab::AppLogger.info(
      message: "Rendered custom webhook template",
      hook_id: hook.id,
      duration_s: duration
    )
    Gitlab::Json.parse(rendered_template)
  rescue JSON::ParserError => e
    raise_custom_webhook_template_error!(e.message)
  rescue TypeError
    raise_custom_webhook_template_error!('You may be trying to access an array value, which is not supported.')
  end
  strong_memoize_attr :request_payload

  def render_custom_template(template, params)
    if Feature.enabled?(:custom_webhook_template_serialization, hook.parent, type: :beta)
      template.gsub(CUSTOM_TEMPLATE_INTERPOLATION_REGEX) do
        value = params.dig(*Regexp.last_match(1).split('.'))
        value_json = value.to_json
        value.is_a?(String) ? value_json[1..-2] : value_json
      end
    else
      template.gsub(CUSTOM_TEMPLATE_INTERPOLATION_REGEX) { params.dig(*Regexp.last_match(1).split('.')) }
    end
  end

  def raise_custom_webhook_template_error!(message)
    raise CustomWebHookTemplateError, "Error while parsing rendered custom webhook template: #{message}"
  end

  def create_broadcast_message(reason)
    params = broadcast_message_params(reason)

    existing_messages = System::BroadcastMessage.current_banner_messages(
      current_path: params[:target_path],
      user_access_level: params[:target_access_levels].first
    ).select { |current_message| current_message.message == params[:message] }

    return unless existing_messages.empty?

    System::BroadcastMessage.new(params).save!
  rescue StandardError => e
    Gitlab::AppLogger.error("Failed to save broadcast message for Webhook ID #{hook.id}, #{reason}")
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
  end

  def broadcast_message_params(reason)
    hook_type = hook.type.gsub('Hook', '').downcase
    message = format(s_("WebHooks|%{reason}. Update or delete the following ") +
      hook_type +
      s_(" hook: %{hook_name} (ID: %{hook_id})."),
      reason: reason,
      hook_name: hook.name,
      hook_id: hook.id).squish

    base_params = {
      message: message,
      starts_at: Time.current,
      ends_at: 3.months.from_now,
      dismissable: true,
      theme: "light-red"
    }

    case hook
    when SystemHook
      base_params.merge(target_path: "/admin", target_access_levels: [])
    when ProjectHook
      base_params.merge(target_path: "/#{hook.project.full_path}", target_access_levels: [Gitlab::Access::OWNER])
    when defined?(GroupHook) && GroupHook
      base_params.merge(target_path: "/#{hook.group.full_path}", target_access_levels: [Gitlab::Access::OWNER])
    end
  end
end
