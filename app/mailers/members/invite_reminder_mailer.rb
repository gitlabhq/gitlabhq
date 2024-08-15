# frozen_string_literal: true

module Members
  class InviteReminderMailer < ApplicationMailer
    include SafeFormatHelper

    helper EmailsHelper

    helper_method :reminder_common_body_options

    layout 'unknown_user_mailer'

    def email(member, token, reminder_index)
      @member = member
      @token = token
      @reminder_index = reminder_index

      return unless valid_to_email?

      @email_instance = email_klass[reminder_index].new

      subject_line = format(email_instance.subject, inviter: member.created_by.name)

      mail_with_locale(to: member.invite_email, subject: EmailsHelper.subject_with_suffix([subject_line]))
    end

    private

    attr_reader :token, :member, :reminder_index, :email_instance

    def email_klass
      {
        0 => FirstEmail,
        1 => SecondEmail,
        2 => LastEmail
      }
    end

    def valid_to_email?
      return true if member.present? && member.created_by && member.invite_to_unknown_user?

      Gitlab::AppLogger.info('Tried to send an email invitation for an invalid member.') if member.blank?

      false
    end

    def reminder_common_body_options(member)
      {
        project_or_group_name: member.source.human_name,
        project_or_group: member.source.model_name.singular,
        role: member.human_access.downcase
      }
    end

    class FirstEmail
      def subject
        s_("InviteReminderEmail|%{inviter}'s invitation to GitLab is pending")
      end

      def salutation
        s_('InviteReminderEmail|Invitation pending')
      end

      alias_method :salutation_html, :salutation

      def body_text
        s_(
          'InviteReminderEmail|%{inviter} is waiting for you to join the ' \
            '%{strong_start}%{project_or_group_name}%{strong_end} %{project_or_group} as a %{role}.'
        )
      end

      def extra_body_options(_)
        {}
      end
    end

    class SecondEmail
      include SafeFormatHelper

      def subject
        s_('InviteReminderEmail|%{inviter} is waiting for you to join GitLab')
      end

      def salutation
        s_('InviteReminderEmail|Hey there!')
      end

      def salutation_html
        wave_emoji_tag = Gitlab::Emoji.gl_emoji_tag(TanukiEmoji.find_by_alpha_code('wave'))
        safe_format(s_('InviteReminderEmail|Hey there %{wave_emoji}'), wave_emoji: wave_emoji_tag)
      end

      def body_text
        s_(
          'InviteReminderEmail|This is a friendly reminder that %{inviter} invited you to join the ' \
            '%{strong_start}%{project_or_group_name}%{strong_end} %{project_or_group} as a %{role}.'
        )
      end

      def extra_body_options(_)
        {}
      end
    end

    class LastEmail
      def subject
        s_('InviteReminderEmail|%{inviter} is still waiting for you to join GitLab')
      end

      def salutation
        s_('InviteReminderEmail|In case you missed it...')
      end

      alias_method :salutation_html, :salutation

      def body_text
        s_(
          "InviteReminderEmail|It's been %{invitation_age} days since %{inviter} invited you to join the " \
            "%{strong_start}%{project_or_group_name}%{strong_end} %{project_or_group} as a %{role}. " \
            "What would you like to do?"
        )
      end

      def extra_body_options(created_at_date)
        {
          invitation_age: (Date.current - created_at_date).to_i
        }
      end
    end
  end
end
