# frozen_string_literal: true

module Projects
  class RecordTargetPlatformsService < BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(project, detector_service)
      @project = project
      @detector_service = detector_service
    end

    def execute
      record_target_platforms
    end

    private

    attr_reader :project, :detector_service

    def target_platforms
      strong_memoize(:target_platforms) do
        Array(detector_service.new(project).execute)
      end
    end

    def record_target_platforms
      return unless target_platforms.present?

      project_setting.target_platforms = target_platforms
      project_setting.save
      project_setting.target_platforms
    end

    def project_setting
      @project_setting ||= ::ProjectSetting.find_or_initialize_by(project: project) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end
