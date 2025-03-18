# frozen_string_literal: true

module Members
  class InviteAcceptedMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member_source, :member, :user, :body_text, :target_model_name

    layout 'mailer'

    def email
      return unless valid_to_email?

      mail_with_locale(
        to: member.created_by.notification_email_for(member_source.notification_group),
        subject: EmailsHelper.subject_with_suffix(['Invitation accepted'])
      )
    end

    private

    delegate :source, to: :member, prefix: true
    delegate :user, to: :member

    def body_text
      s_(
        'Notify|%{invite_email}, now known as %{user_name}, has accepted your invitation ' \
          'to join the %{target_name} %{target_model_name}.'
      )
    end

    def target_model_name
      member_source.model_name.singular
    end

    def valid_to_email?
      if member.blank?
        Gitlab::AppLogger.info('Tried to send an email acceptance for an invalid member.')
        return false
      end

      return false if member_source.is_a?(Project) && !member.notifiable?(:subscription)

      member.created_by.present?
    end

    def member
      params[:member]
    end
  end
end
