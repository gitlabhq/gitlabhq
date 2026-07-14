# frozen_string_literal: true

class RepositoryCheckMailer < ApplicationMailer
  layout 'mailer'

  helper EmailsHelper

  def notify(failed_count, recipient)
    @message =
      if failed_count == 1
        "One project failed its last repository check"
      else
        "#{failed_count} projects failed their last repository check"
      end

    mail_with_locale(
      to: recipient,
      subject: "GitLab Admin | #{@message}"
    )
  end
end
