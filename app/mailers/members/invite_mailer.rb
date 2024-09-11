# frozen_string_literal: true

module Members
  class InviteMailer < ApplicationMailer
    include SafeFormatHelper

    helper EmailsHelper
    helper AvatarsHelper

    helper_method :member_source, :member, :invited_to_description

    layout 'unknown_user_mailer'

    INITIAL_INVITE = 'initial_email'

    def initial_email(member, token)
      @member = member
      @token = token

      return unless member_exists?

      Gitlab::Tracking.event(self.class.name, 'invite_email_sent', label: 'invite_email')

      mail_with_locale(
        to: member.invite_email, subject: EmailsHelper.subject_with_suffix([email_subject_text]), **email_headers
      )
    end

    private

    attr_reader :token, :member

    def member_source
      member.source
    end

    def email_subject_text
      if member.created_by
        safe_format(
          s_('MemberInviteEmail|%{member_name} invited you to join GitLab'),
          member_name: member.created_by.name)

      else
        safe_format(
          s_('MemberInviteEmail|Invitation to join the %{project_or_group} %{project_or_group_name}'),
          project_or_group: member_source.human_name, project_or_group_name: member_source.model_name.singular)

      end
    end

    def email_headers
      if Gitlab::CurrentSettings.mailgun_events_enabled?
        {
          'X-Mailgun-Tag' => ::Members::Mailgun::INVITE_EMAIL_TAG,
          'X-Mailgun-Variables' => { ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY => token }.to_json
        }
      else
        {}
      end
    end

    def member_exists?
      Gitlab::AppLogger.info('Tried to send an email invitation for a non existent member.') if member.blank?

      member.present?
    end

    def invited_to_description(source)
      default_description =
        case source
        when Project
          s_(
            'InviteEmail|Projects are used to host and collaborate on code, track issues, and continuously build, ' \
              'test, and deploy your app with built-in GitLab CI/CD.'
          )
        when Group
          s_(
            'InviteEmail|Groups assemble related projects together and grant members access to several projects at ' \
              'once.'
          )
        end

      (source.description || default_description).truncate(200, separator: ' ')
    end
  end
end
