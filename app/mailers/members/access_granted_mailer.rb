# frozen_string_literal: true

module Members
  class AccessGrantedMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member_source, :member, :member_source_organization

    layout 'mailer'

    def email
      return unless valid_to_email?

      mail_with_locale(
        to: member.user.notification_email_for(notification_group),
        subject: EmailsHelper.subject_with_prefix_and_suffix([email_subject_text])
      )
    end

    private

    delegate :source, to: :member, prefix: true

    def valid_to_email?
      if member.blank?
        Gitlab::AppLogger.info('Tried to send an access granted email for an invalid member.')
        return false
      end

      true
    end

    def member
      params[:member]
    end

    def member_source_organization
      member_source.organization
    end

    def notification_group
      member_source_type.casecmp?('project') ? member_source.group : member_source
    end

    def member_source_type
      params[:member_source_type]
    end

    def email_subject_text
      "Access to the #{member_source.human_name} #{member_source.model_name.singular} was granted"
    end
  end
end
