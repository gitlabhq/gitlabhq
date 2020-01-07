# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module SelfMonitoring
      module Helpers
        def application_settings
          @application_settings ||= ApplicationSetting.current_without_cache
        end

        def project_created?
          self_monitoring_project.present?
        end

        def self_monitoring_project
          application_settings.instance_administration_project
        end

        def self_monitoring_project_id
          application_settings.instance_administration_project_id
        end
      end
    end
  end
end
