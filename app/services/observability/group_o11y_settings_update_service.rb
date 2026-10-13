# frozen_string_literal: true

module Observability
  class GroupO11ySettingsUpdateService
    InvalidServiceNameError = Class.new(StandardError)

    SERVICE_NAME_REGEX = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    INVALID_SERVICE_NAME_MESSAGE = 'O11y service name is invalid'

    def execute(settings, settings_params)
      params = manage_params(settings_params)

      if settings.update(params)
        ServiceResponse.success(payload: { settings: settings })
      else
        ServiceResponse.error(message: settings.errors.full_messages.join(', '))
      end
    rescue InvalidServiceNameError
      ServiceResponse.error(message: INVALID_SERVICE_NAME_MESSAGE)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      ServiceResponse.error(message: e.message)
    rescue StandardError => e
      ServiceResponse.error(message: "An unexpected error occurred: #{e.message}")
    end

    private

    attr_reader :settings

    def manage_params(params)
      set_url(filter_blank_params(params))
    end

    def set_url(params)
      service_name = params.delete(:o11y_service_name)
      return params unless service_name.present?

      raise InvalidServiceNameError unless service_name.match?(SERVICE_NAME_REGEX)

      params[:o11y_service_url] = "https://#{service_name}.gitlab-o11y.com"
      params
    end

    def filter_blank_params(params)
      params.reject { |_key, value| value.blank? }
    end
  end
end
