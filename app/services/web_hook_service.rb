class WebHookService
  class InternalErrorResponse
    attr_reader :body, :headers, :code

    def initialize
      @headers = Gitlab::HTTP::Response::Headers.new({})
      @body = ''
      @code = 'internal error'
    end
  end

  attr_accessor :hook, :data, :hook_name, :request_options

  def initialize(hook, data, hook_name)
    @hook = hook
    @data = data
    @hook_name = hook_name.to_s
    @request_options = { timeout: Gitlab.config.gitlab.webhook_timeout }
    @request_options.merge!(allow_local_requests: true) if @hook.is_a?(SystemHook)
  end

  def execute
    start_time = Time.now

    response = if parsed_url.userinfo.blank?
                 make_request(hook.url)
               else
                 make_request_with_auth
               end

    log_execution(
      trigger: hook_name,
      url: hook.url,
      request_data: data,
      response: response,
      execution_duration: Time.now - start_time
    )

    {
      status: :success,
      http_status: response.code,
      message: response.to_s
    }
  rescue SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, Net::ReadTimeout => e
    log_execution(
      trigger: hook_name,
      url: hook.url,
      request_data: data,
      response: InternalErrorResponse.new,
      execution_duration: Time.now - start_time,
      error_message: e.to_s
    )

    Rails.logger.error("WebHook Error => #{e}")

    {
      status: :error,
      message: e.to_s
    }
  end

  def async_execute
    WebHookWorker.perform_async(hook.id, data, hook_name)
  end

  private

  def parsed_url
    @parsed_url ||= URI.parse(hook.url)
  end

  def make_request(url, basic_auth = false)
    Gitlab::HTTP.post(url,
      body: data.to_json,
      headers: build_headers(hook_name),
      verify: hook.enable_ssl_verification,
      basic_auth: basic_auth,
      **request_options)
  end

  def make_request_with_auth
    post_url = hook.url.gsub("#{parsed_url.userinfo}@", '')
    basic_auth = {
      username: CGI.unescape(parsed_url.user),
      password: CGI.unescape(parsed_url.password)
    }
    make_request(post_url, basic_auth)
  end

  def log_execution(trigger:, url:, request_data:, response:, execution_duration:, error_message: nil)
    # logging for ServiceHook's is not available
    return if hook.is_a?(ServiceHook)

    WebHookLog.create(
      web_hook: hook,
      trigger: trigger,
      url: url,
      execution_duration: execution_duration,
      request_headers: build_headers(hook_name),
      request_data: request_data,
      response_headers: format_response_headers(response),
      response_body: safe_response_body(response),
      response_status: response.code,
      internal_error_message: error_message
    )
  end

  def build_headers(hook_name)
    @headers ||= begin
      {
        'Content-Type' => 'application/json',
        'X-Gitlab-Event' => hook_name.singularize.titleize
      }.tap do |hash|
        hash['X-Gitlab-Token'] = Gitlab::Utils.remove_line_breaks(hook.token) if hook.token.present?
      end
    end
  end

  # Make response headers more stylish
  # Net::HTTPHeader has downcased hash with arrays: { 'content-type' => ['text/html; charset=utf-8'] }
  # This method format response to capitalized hash with strings: { 'Content-Type' => 'text/html; charset=utf-8' }
  def format_response_headers(response)
    response.headers.each_capitalized.to_h
  end

  def safe_response_body(response)
    return '' unless response.body

    response.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
end
