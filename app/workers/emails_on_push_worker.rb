class EmailsOnPushWorker
  include ApplicationWorker

  attr_reader :email, :skip_premailer

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

    diff_refs = nil
    compare = nil
    reverse_compare = false

    if action == :push
      compare = CompareService.new(project, after_sha)
        .execute(project, before_sha)
      diff_refs = compare.diff_refs

      return false if compare.same

      if compare.commits.empty?
        compare = CompareService.new(project, before_sha)
          .execute(project, after_sha)
        diff_refs = compare.diff_refs

        reverse_compare = true

        return false if compare.commits.empty?
      end
    end

    recipients.split.each do |recipient|
      begin
        send_email(
          recipient,
          project_id,
          author_id:                 author_id,
          ref:                       ref,
          action:                    action,
          compare:                   compare,
          reverse_compare:           reverse_compare,
          diff_refs:                 diff_refs,
          send_from_committer_email: send_from_committer_email,
          disable_diffs:             disable_diffs
        )

      # These are input errors and won't be corrected even if Sidekiq retries
      rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
        logger.info("Failed to send e-mail for project '#{project.full_name}' to #{recipient}: #{e}")
      end
    end
  ensure
    @email = nil
    compare = nil
    GC.start
  end

  private

  def send_email(recipient, project_id, options)
    # Generating the body of this email can be expensive, so only do it once
    @skip_premailer ||= email.present?
    @email ||= Notify.repository_push_email(project_id, options)

    email.to = recipient
    email.add_message_id
    email.header[:skip_premailer] = true if skip_premailer
    email.deliver_now
  end
end
