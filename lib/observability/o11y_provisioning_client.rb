# frozen_string_literal: true

module Observability
  class O11yProvisioningClient
    PRODUCTION_GROUP_ID = 111938901
    DEFAULT_API_KEY = 'use-this-key-for-testing-api-key'
    PROVISIONER_API = 'https://provisioner.gitlab-o11y.com/api/v1/provision_requests'

    def provision_group(group, user)
      api_request_data = build_api_request_data(group, user)
      api_success = make_api_request(api_request_data)

      if api_success
        {
          success: true,
          settings_params: build_settings_params(api_request_data)
        }
      else
        {
          success: false,
          error: 'API call failed for observability group setting'
        }
      end
    end

    private

    def build_api_request_data(group, user)
      {
        group_id: group.id,
        email: user.email,
        password: SecureRandom.hex(16),
        encryption_key: SecureRandom.hex(32)
      }
    end

    def build_settings_params(api_request_data)
      {
        o11y_service_name: api_request_data[:group_id].to_s,
        o11y_service_user_email: "#{api_request_data[:group_id]}@gitlab-o11y.com",
        o11y_service_password: api_request_data[:password],
        o11y_service_post_message_encryption_key: api_request_data[:encryption_key]
      }
    end

    def make_api_request(api_request_data)
      response = Gitlab::HTTP.post(
        PROVISIONER_API,
        body: { o11y_provision_request: api_request_data }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => "GitLab/#{Gitlab::VERSION}",
          'X-API-Key' => api_key
        },
        timeout: 30
      )

      response.success?
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_api_error(e, api_request_data[:group_id])
      false
    end

    def handle_api_error(error, group_id)
      filtered_message = case error
                         when Gitlab::HTTP_V2::BlockedUrlError, Gitlab::HTTP_V2::RedirectionTooDeep
                           Gitlab::UrlSanitizer.sanitize(error.message)
                         else
                           error.message
                         end

      log_error(
        message: 'API request error for observability setting',
        group_id: group_id,
        error: filtered_message,
        error_class: error.class.name
      )
    end

    def api_key
      Rails.env.production? ? production_api_key : DEFAULT_API_KEY
    end

    def production_api_key
      Observability::GroupO11ySetting.find_by_group_id(PRODUCTION_GROUP_ID)
                                     &.o11y_service_post_message_encryption_key
    end

    def log_error(data)
      Gitlab::AppLogger.error(data)
    end
  end
end
