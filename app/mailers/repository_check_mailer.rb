class RepositoryCheckMailer < BaseMailer
  def notify(failed_count)
    if failed_count == 1
      @message = "一个项目仓库检查失败"
    else
      @message = "#{failed_count} 个项目仓库检查失败"
    end

    mail(
      to: User.admins.pluck(:email),
      subject: "GitLab 后台 | #{@message}"
    )
  end
end
