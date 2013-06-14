module Emails
  module Commits
    style_body = File.read(Rails.public_path + "/mail_compare.css")
    def receive_commit_email(project_id, author_id, data)
      @project = Project.find(project_id)
      @user = User.find(author_id)
      @data = data
      @repository = @project.repository
      compare = Gitlab::Git::Compare.new(@repository, data[:before], data[:after])
      @diffs = compare.diffs
      @commit = compare.commit
      @commits = compare.commits
      @refs_are_same = compare.same
      @ref = data[:ref]

      Gitlab::AppLogger.info "#{@project.name}, #{@user.username}, #{data[:ref]} receive a push"
      user_emails = @project.users.map {|u| u.email}
      #inline the resource
      attachments.inline["mail_compare.css"] = style_body
      #puts user_emails
      mail(to: user_emails, subject: subject("receive a push"))
    end
  end
end
