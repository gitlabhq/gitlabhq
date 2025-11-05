# frozen_string_literal: true

module Emails
  module Members
    extend ActiveSupport::Concern
    include MembersHelper
    include Gitlab::Experiment::Dsl

    included do
      helper_method :member, :member_source, :member_source_organization
      helper_method :experiment
    end

    def member_access_granted_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      return unless member_exists?

      email_with_layout(
        to: member.user.notification_email_for(notification_group),
        subject: subject("Access to the #{member_source.human_name} #{member_source.model_name.singular} was granted"))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def member
      @member ||= Member.find_by(id: @member_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def member_source
      @member_source ||= member.source
    end

    def member_source_organization
      @member_source_organization ||= member_source.organization
    end

    def notification_group
      @member_source_type.casecmp?('project') ? member_source.group : member_source
    end

    private

    def member_exists?
      if member.blank?
        Gitlab::AppLogger.info("Tried to send an email invitation for a deleted group. Member id: #{@member_id}")
      end

      member.present?
    end

    def member_source_class
      @member_source_type.classify.constantize
    end
  end
end

Emails::Members.prepend_mod_with('Emails::Members')
