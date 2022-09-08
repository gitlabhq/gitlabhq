# frozen_string_literal: true

class RepositoryCheckMailer < ApplicationMailer
  # rubocop: disable CodeReuse/ActiveRecord
  layout 'empty_mailer'

  helper EmailsHelper

  def notify(failed_count)
    @message =
      if failed_count == 1
        "One project failed its last repository check"
      else
        "#{failed_count} projects failed their last repository check"
      end

    mail_with_locale(
      to: User.admins.active.pluck(:email),
      subject: "GitLab Admin | #{@message}"
    )
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
