class RepositoryCheckMailerPreview < ActionMailer::Preview
  def notify
    RepositoryCheckMailer.notify(3).message
  end
end
