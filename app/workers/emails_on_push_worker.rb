class EmailsOnPushWorker
  include Sidekiq::Worker

  def perform(project_id, recipients, push_data)
    project = Project.find(project_id)
    before_sha = push_data["before"]
    after_sha = push_data["after"]
    branch = push_data["ref"]
    author_id = push_data["user_id"]

    if before_sha =~ /^000000/ || after_sha =~ /^000000/
      # skip if new branch was pushed or branch was removed
      return true
    end

    compare = Gitlab::Git::Compare.new(project.repository.raw_repository, before_sha, after_sha, MergeRequestDiff::COMMITS_SAFE_SIZE)

    # Do not send emails if git compare failed
    return false unless compare && compare.commits.present?

    recipients.split(" ").each do |recipient|
      Notify.repository_push_email(project_id, recipient, author_id, branch, compare).deliver
    end
  end
end
