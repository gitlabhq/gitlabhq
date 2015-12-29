class EmailsOnPushWorker
  include Sidekiq::Worker

  def perform(project_id, recipients, push_data, options = {})
    options.symbolize_keys!
    options.reverse_merge!(
      send_from_committer_email:  false,
      disable_diffs:              false
    )
    send_from_committer_email = options[:send_from_committer_email]
    disable_diffs = options[:disable_diffs]

    project = Project.find(project_id)
    before_sha = push_data["before"]
    after_sha = push_data["after"]
    ref = push_data["ref"]
    author_id = push_data["user_id"]

    action =
      if Gitlab::Git.blank_ref?(before_sha)
        :create
      elsif Gitlab::Git.blank_ref?(after_sha)
        :delete
      else
        :push
      end

    compare = nil
    reverse_compare = false
    if action == :push
      compare = Gitlab::Git::Compare.new(project.repository.raw_repository, before_sha, after_sha)

      return false if compare.same

      if compare.commits.empty?
        compare = Gitlab::Git::Compare.new(project.repository.raw_repository, after_sha, before_sha)

        reverse_compare = true

        return false if compare.commits.empty?
      end
    end

    recipients.split(" ").each do |recipient|
      begin
        Notify.repository_push_email(
          project_id,
          recipient,
          author_id:                  author_id,
          ref:                        ref,
          action:                     action,
          compare:                    compare,
          reverse_compare:            reverse_compare,
          send_from_committer_email:  send_from_committer_email,
          disable_diffs:              disable_diffs
        ).deliver_now
      # These are input errors and won't be corrected even if Sidekiq retries
      rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
        logger.info("Failed to send e-mail for project '#{project.name_with_namespace}' to #{recipient}: #{e}")
      end
    end
  ensure
    compare = nil
    GC.start
  end
end
