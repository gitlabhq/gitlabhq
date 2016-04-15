class RepositoryCheckMailer < BaseMailer
  def notify(failed_count)
    if failed_count == 1
      @message = "One project failed its last repository check"
    else
      @message = "#{failed_count} projects failed their last repository check"
    end

    mail(
      to: User.admins.pluck(:email),
      subject: @message
    )
  end
end
