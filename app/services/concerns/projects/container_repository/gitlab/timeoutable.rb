# frozen_string_literal: true

module Projects
  module ContainerRepository
    module Gitlab
      module Timeoutable
        extend ActiveSupport::Concern

        DISABLED_TIMEOUTS = [nil, 0].freeze

        TimeoutError = Class.new(StandardError)

        private

        def timeout?(start_time)
          return false if service_timeout.in?(DISABLED_TIMEOUTS)

          (Time.zone.now - start_time) > service_timeout
        end

        def service_timeout
          ::Gitlab::CurrentSettings.current_application_settings.container_registry_delete_tags_service_timeout
        end
      end
    end
  end
end
