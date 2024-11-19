# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Mailers
      class UnconfirmMailer < ::Notify
        prepend_view_path(File.join(__dir__, 'views'))

        def unconfirm_notification_email(user)
          @user = user
          @verification_from_mail = Gitlab.config.gitlab.email_from

          mail_with_locale(
            template_path: 'unconfirm_mailer',
            template_name: 'unconfirm_notification_email',
            to: @user.notification_email_or_default,
            subject: subject('GitLab email verification request')
          )
        end
      end
    end
  end
end
