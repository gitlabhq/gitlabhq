# frozen_string_literal: true

module AsyncDeviseEmail
  extend ActiveSupport::Concern
  include AfterCommitQueue

  private

  # Added according to https://github.com/plataformatec/devise/blob/7df57d5081f9884849ca15e4fde179ef164a575f/README.md#activejob-integration
  def send_devise_notification(notification, *args)
    return true unless can?(:receive_notifications)

    run_after_commit_or_now do
      devise_mailer.__send__(notification, self, *args).deliver_later # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
