# frozen_string_literal: true

module Members
  class ExpirationDateUpdatedMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member_source, :member

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
        Gitlab::AppLogger.info('Tried to send expiration date updated email for an invalid member.')
        return false
      end

      unless member_source.is_a?(Group)
        Gitlab::AppLogger.info('Tried to send expiration date updated email for a non-group member.')
        return false
      end

      unless member.notifiable?(:mention)
        Gitlab::AppLogger.info('Tried to send expiration date updated email for a non-notifiable member.')
        return false
      end

      true
    end

    def member
      params[:member]
    end

    def notification_group
      member_source_type.casecmp?('project') ? member_source.group : member_source
    end

    def member_source_type
      params[:member_source_type]
    end

    def email_subject_text
      if member.expires?
        _('Group membership expiration date changed')
      else
        _('Group membership expiration date removed')
      end
    end
  end
end
