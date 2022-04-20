# frozen_string_literal: true

module Projects
  class RecordTargetPlatformsService < BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      record_target_platforms
    end

    private

    def target_platforms
      strong_memoize(:target_platforms) do
        AppleTargetPlatformDetectorService.new(project).execute
      end
    end

    def record_target_platforms
      return unless target_platforms.present?

      setting = ::ProjectSetting.find_or_initialize_by(project: project) # rubocop:disable CodeReuse/ActiveRecord
      setting.target_platforms = target_platforms
      setting.save

      setting.target_platforms
    end
  end
end
