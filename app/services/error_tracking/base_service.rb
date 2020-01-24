# frozen_string_literal: true

module ErrorTracking
  class BaseService < ::BaseService
    def execute
      unauthorized = check_permissions
      return unauthorized if unauthorized

      begin
        response = fetch
      rescue Sentry::Client::Error => e
        return error(e.message, :bad_request)
      rescue Sentry::Client::MissingKeysError => e
        return error(e.message, :internal_server_error)
      end

      errors = parse_errors(response)
      return errors if errors

      success(parse_response(response))
    end

    private

    def fetch
      raise NotImplementedError,
          "#{self.class} does not implement #{__method__}"
    end

    def parse_response(response)
      raise NotImplementedError,
          "#{self.class} does not implement #{__method__}"
    end

    def check_permissions
      return error('Error Tracking is not enabled') unless enabled?
      return error('Access denied', :unauthorized) unless can_read?
    end

    def parse_errors(response)
      return error('Not ready. Try again later', :no_content) unless response
      return error(response[:error], http_status_for(response[:error_type])) if response[:error].present?
    end

    def http_status_for(error_type)
      case error_type
      when ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_MISSING_KEYS
        :internal_server_error
      else
        :bad_request
      end
    end

    def project_error_tracking_setting
      project.error_tracking_setting
    end

    def enabled?
      project_error_tracking_setting&.enabled?
    end

    def can_read?
      can?(current_user, :read_sentry_issue, project)
    end
  end
end
