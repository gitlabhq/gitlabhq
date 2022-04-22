# frozen_string_literal: true

module Projects
  class InProductMarketingCampaignEmailsService
    include Gitlab::Experiment::Dsl

    def initialize(project, campaign)
      @project = project
      @campaign = campaign
      @sent_email_records = ::Users::InProductMarketingEmailRecords.new
    end

    def execute
      send_emails
    end

    private

    attr_reader :project, :campaign, :sent_email_records

    def send_emails
      project_users.each do |user|
        send_email(user)
      end

      sent_email_records.save!
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def project_users
      @project_users ||= project.users
        .where(email_opted_in: true)
        .merge(Users::InProductMarketingEmail.without_campaign(campaign))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def project_users_max_access_levels
      ids = project_users.map(&:id)
      @project_users_max_access_levels ||= project.team.max_member_access_for_user_ids(ids)
    end

    def send_email(user)
      return unless user.can?(:receive_notifications)
      return unless target_user?(user)

      Notify.build_ios_app_guide_email(user.notification_email_or_default).deliver_later

      sent_email_records.add(user, campaign: campaign)
      experiment(:build_ios_app_guide_email, project: project).track(:email_sent)
    end

    def target_user?(user)
      max_access_level = project_users_max_access_levels[user.id]
      max_access_level >= Gitlab::Access::DEVELOPER
    end
  end
end
