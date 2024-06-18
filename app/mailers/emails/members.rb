# frozen_string_literal: true

module Emails
  module Members
    extend ActiveSupport::Concern
    include MembersHelper
    include Gitlab::Experiment::Dsl

    included do
      helper_method :member_source, :member
      helper_method :experiment
    end

    def member_access_requested_email(member_source_type, member_id, recipient_id)
      @member_source_type = member_source_type
      @member_id = member_id

      return unless member_exists?

      user = User.find(recipient_id)

      email_with_layout(
        to: user.notification_email_for(notification_group),
        subject: subject("Request to join the #{member_source.human_name} #{member_source.model_name.singular}"))
    end

    def member_access_granted_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      return unless member_exists?

      email_with_layout(
        to: member.user.notification_email_for(notification_group),
        subject: subject("Access to the #{member_source.human_name} #{member_source.model_name.singular} was granted"))
    end

    def member_access_denied_email(member_source_type, source_id, user_id)
      @member_source_type = member_source_type
      @member_source = member_source_class.find(source_id)

      user = User.find(user_id)

      @source_hidden = !member_source.readable_by?(user)

      human_name = @source_hidden ? 'Hidden' : member_source.human_name

      email_with_layout(
        to: user.notification_email_for(notification_group),
        subject: subject("Access to the #{human_name} #{member_source.model_name.singular} was denied"))
    end

    def member_invited_reminder_email(member_source_type, member_id, token, reminder_index)
      @member_source_type = member_source_type
      @member_id = member_id
      @token = token
      @reminder_index = reminder_index

      return unless member_exists? && member.created_by && member.invite_to_unknown_user?

      subjects = {
        0 => s_("InviteReminderEmail|%{inviter}'s invitation to GitLab is pending"),
        1 => s_('InviteReminderEmail|%{inviter} is waiting for you to join GitLab'),
        2 => s_('InviteReminderEmail|%{inviter} is still waiting for you to join GitLab')
      }

      subject_line = subjects[reminder_index] % { inviter: member.created_by.name }

      email_with_layout(
        layout: 'unknown_user_mailer',
        to: member.invite_email,
        subject: subject(subject_line)
      )
    end

    def member_invite_accepted_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      return unless member_exists?
      return unless member.created_by

      email_with_layout(
        to: member.created_by.notification_email_for(notification_group),
        subject: subject('Invitation accepted'))
    end

    def member_invite_declined_email(member_source_type, source_id, invite_email, created_by_id)
      return unless created_by_id

      @member_source_type = member_source_type
      @member_source = member_source_class.find(source_id)
      @invite_email = invite_email

      user = User.find(created_by_id)

      email_with_layout(
        to: user.notification_email_for(notification_group),
        subject: subject('Invitation declined'))
    end

    def member_expiration_date_updated_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      return unless member_exists?

      subject = if member.expires?
                  _('Group membership expiration date changed')
                else
                  _('Group membership expiration date removed')
                end

      email_with_layout(
        to: member.user.notification_email_for(notification_group),
        subject: subject(subject))
    end

    def member_about_to_expire_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      return unless member_exists?
      return unless member.expires_at

      @days_to_expire = (member.expires_at - Date.today).to_i

      return if @days_to_expire <= 0

      email_with_layout(
        to: member.user.notification_email_for(notification_group),
        subject: subject(s_("Your membership will expire in %{days_to_expire} days") % { days_to_expire: @days_to_expire }))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def member
      @member ||= Member.find_by(id: @member_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def member_source
      @member_source ||= member.source
    end

    def notification_group
      @member_source_type.casecmp?('project') ? member_source.group : member_source
    end

    private

    def member_exists?
      Gitlab::AppLogger.info("Tried to send an email invitation for a deleted group. Member id: #{@member_id}") if member.blank?
      member.present?
    end

    def member_source_class
      @member_source_type.classify.constantize
    end
  end
end

Emails::Members.prepend_mod_with('Emails::Members')
