# frozen_string_literal: true

module Observability
  class GroupO11ySettingsUpdateService
    def execute(settings, settings_params)
      if settings.update(manage_params(settings_params))
        ServiceResponse.success(payload: { settings: settings })
      else
        ServiceResponse.error(message: settings.errors.full_messages.join(', '))
      end
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

      params[:o11y_service_url] = "https://#{service_name}.gitlab-o11y.com" if service_name.present?
      params
    end

    def filter_blank_params(params)
      params.reject { |_key, value| value.blank? }
    end
  end
end
