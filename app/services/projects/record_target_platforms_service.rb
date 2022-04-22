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

      project_setting.target_platforms = target_platforms
      project_setting.save

      send_build_ios_app_guide_email

      project_setting.target_platforms
    end

    def project_setting
      @project_setting ||= ::ProjectSetting.find_or_initialize_by(project: project) # rubocop:disable CodeReuse/ActiveRecord
    end

    def experiment_candidate?
      experiment(:build_ios_app_guide_email, project: project).run
    end

    def send_build_ios_app_guide_email
      return unless experiment_candidate?

      campaign = Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE
      Projects::InProductMarketingCampaignEmailsService.new(project, campaign).execute
    end
  end
end
