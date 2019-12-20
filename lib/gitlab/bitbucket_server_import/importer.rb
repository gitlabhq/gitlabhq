# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class Importer
      attr_reader :recover_missing_commits
      attr_reader :project, :project_key, :repository_slug, :client, :errors, :users
      attr_accessor :logger

      REMOTE_NAME = 'bitbucket_server'
      BATCH_SIZE = 100

      TempBranch = Struct.new(:name, :sha)

      def self.imports_repository?
        true
      end

      def self.refmap
        [:heads, :tags, '+refs/pull-requests/*/to:refs/merge-requests/*/head']
      end

      # Unlike GitHub, you can't grab the commit SHAs for pull requests that
      # have been closed but not merged even though Bitbucket has these
      # commits internally. We can recover these pull requests by creating a
      # branch with the Bitbucket REST API, but by default we turn this
      # behavior off.
      def initialize(project, recover_missing_commits: false)
        @project = project
        @recover_missing_commits = recover_missing_commits
        @project_key = project.import_data.data['project_key']
        @repository_slug = project.import_data.data['repo_slug']
        @client = BitbucketServer::Client.new(project.import_data.credentials)
        @formatter = Gitlab::ImportFormatter.new
        @errors = []
        @users = {}
        @temp_branches = []
        @logger = Gitlab::Import::Logger.build
      end

      def execute
        import_repository
        import_pull_requests
        delete_temp_branches
        handle_errors

        log_info(stage: "complete")

        true
      end

      private

      def handle_errors
        return unless errors.any?

        project.import_state.update_column(:last_error, {
          message: 'The remote data could not be fully imported.',
          errors: errors
        }.to_json)
      end

      def gitlab_user_id(email)
        find_user_id(email) || project.creator_id
      end

      def find_user_id(email)
        return unless email

        return users[email] if users.key?(email)

        user = User.find_by_any_email(email, confirmed: true)
        users[email] = user&.id

        user&.id
      end

      def repo
        @repo ||= client.repo(project_key, repository_slug)
      end

      def sha_exists?(sha)
        project.repository.commit(sha)
      end

      def temp_branch_name(pull_request, suffix)
        "gitlab/import/pull-request/#{pull_request.iid}/#{suffix}"
      end

      # This method restores required SHAs that GitLab needs to create diffs
      # into branch names as the following:
      #
      # gitlab/import/pull-request/N/{to,from}
      def restore_branches(pull_requests)
        shas_to_restore = []

        pull_requests.each do |pull_request|
          shas_to_restore << TempBranch.new(temp_branch_name(pull_request, :from),
                                            pull_request.source_branch_sha)
          shas_to_restore << TempBranch.new(temp_branch_name(pull_request, :to),
                                            pull_request.target_branch_sha)
        end

        # Create the branches on the Bitbucket Server first
        created_branches = restore_branch_shas(shas_to_restore)

        @temp_branches += created_branches
        # Now sync the repository so we get the new branches
        import_repository unless created_branches.empty?
      end

      def restore_branch_shas(shas_to_restore)
        shas_to_restore.each_with_object([]) do |temp_branch, branches_created|
          branch_name = temp_branch.name
          sha = temp_branch.sha

          next if sha_exists?(sha)

          begin
            client.create_branch(project_key, repository_slug, branch_name, sha)
            branches_created << temp_branch
          rescue BitbucketServer::Connection::ConnectionError => e
            log_warn(message: "Unable to recreate branch", sha: sha, error: e.message)
          end
        end
      end

      def import_repository
        log_info(stage: 'import_repository', message: 'starting import')

        project.ensure_repository
        project.repository.fetch_as_mirror(project.import_url, refmap: self.class.refmap, remote_name: REMOTE_NAME)

        log_info(stage: 'import_repository', message: 'finished import')
      rescue Gitlab::Shell::Error => e
        Gitlab::ErrorTracking.log_exception(
          e,
          stage: 'import_repository', message: 'failed import', error: e.message
        )

        # Expire cache to prevent scenarios such as:
        # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
        # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
        project.repository.expire_content_cache if project.repository_exists?

        raise
      end

      # Bitbucket Server keeps tracks of references for open pull requests in
      # refs/heads/pull-requests, but closed and merged requests get moved
      # into hidden internal refs under stash-refs/pull-requests. Unless the
      # SHAs involved are at the tip of a branch or tag, there is no way to
      # retrieve the server for those commits.
      #
      # To avoid losing history, we use the Bitbucket API to re-create the branch
      # on the remote server. Then we have to issue a `git fetch` to download these
      # branches.
      def import_pull_requests
        pull_requests = client.pull_requests(project_key, repository_slug).to_a

        # Creating branches on the server and fetching the newly-created branches
        # may take a number of network round-trips. Do this in batches so that we can
        # avoid doing a git fetch for every new branch.
        pull_requests.each_slice(BATCH_SIZE) do |batch|
          restore_branches(batch) if recover_missing_commits

          batch.each do |pull_request|
            import_bitbucket_pull_request(pull_request)
          rescue StandardError => e
            Gitlab::ErrorTracking.log_exception(
              e,
              stage: 'import_pull_requests', iid: pull_request.iid, error: e.message
            )

            errors << { type: :pull_request, iid: pull_request.iid, errors: e.message, backtrace: backtrace.join("\n"), raw_response: pull_request.raw }
          end
        end
      end

      def delete_temp_branches
        @temp_branches.each do |branch|
          client.delete_branch(project_key, repository_slug, branch.name, branch.sha)
          project.repository.delete_branch(branch.name)
        rescue BitbucketServer::Connection::ConnectionError => e
          Gitlab::ErrorTracking.log_exception(
            e,
            stage: 'delete_temp_branches', branch: branch.name, error: e.message
          )

          @errors << { type: :delete_temp_branches, branch_name: branch.name, errors: e.message }
        end
      end

      def import_bitbucket_pull_request(pull_request)
        log_info(stage: 'import_bitbucket_pull_requests', message: 'starting', iid: pull_request.iid)

        description = ''
        description += @formatter.author_line(pull_request.author) unless find_user_id(pull_request.author_email)
        description += pull_request.description if pull_request.description
        author_id = gitlab_user_id(pull_request.author_email)

        attributes = {
          iid: pull_request.iid,
          title: pull_request.title,
          description: description,
          source_project_id: project.id,
          source_branch: Gitlab::Git.ref_name(pull_request.source_branch_name),
          source_branch_sha: pull_request.source_branch_sha,
          target_project_id: project.id,
          target_branch: Gitlab::Git.ref_name(pull_request.target_branch_name),
          target_branch_sha: pull_request.target_branch_sha,
          state_id: MergeRequest.available_states[pull_request.state],
          author_id: author_id,
          assignee_id: nil,
          created_at: pull_request.created_at,
          updated_at: pull_request.updated_at
        }

        creator = Gitlab::Import::MergeRequestCreator.new(project)
        merge_request = creator.execute(attributes)

        import_pull_request_comments(pull_request, merge_request) if merge_request.persisted?

        log_info(stage: 'import_bitbucket_pull_requests', message: 'finished', iid: pull_request.iid)
      end

      def import_pull_request_comments(pull_request, merge_request)
        log_info(stage: 'import_pull_request_comments', message: 'starting', iid: merge_request.iid)

        comments, other_activities = client.activities(project_key, repository_slug, pull_request.iid).partition(&:comment?)

        merge_event = other_activities.find(&:merge_event?)
        import_merge_event(merge_request, merge_event) if merge_event

        inline_comments, pr_comments = comments.partition(&:inline_comment?)

        import_inline_comments(inline_comments.map(&:comment), merge_request)
        import_standalone_pr_comments(pr_comments.map(&:comment), merge_request)

        log_info(stage: 'import_pull_request_comments', message: 'finished', iid: merge_request.iid,
                 merge_event_found: merge_event.present?,
                 inline_comments_count: inline_comments.count,
                 standalone_pr_comments: pr_comments.count)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def import_merge_event(merge_request, merge_event)
        log_info(stage: 'import_merge_event', message: 'starting', iid: merge_request.iid)

        committer = merge_event.committer_email

        user_id = gitlab_user_id(committer)
        timestamp = merge_event.merge_timestamp
        merge_request.update({ merge_commit_sha: merge_event.merge_commit })
        metric = MergeRequest::Metrics.find_or_initialize_by(merge_request: merge_request)
        metric.update(merged_by_id: user_id, merged_at: timestamp)

        log_info(stage: 'import_merge_event', message: 'finished', iid: merge_request.iid)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def import_inline_comments(inline_comments, merge_request)
        log_info(stage: 'import_inline_comments', message: 'starting', iid: merge_request.iid)

        inline_comments.each do |comment|
          position = build_position(merge_request, comment)
          parent = create_diff_note(merge_request, comment, position)

          next unless parent&.persisted?

          discussion_id = parent.discussion_id

          comment.comments.each do |reply|
            create_diff_note(merge_request, reply, position, discussion_id)
          end
        end

        log_info(stage: 'import_inline_comments', message: 'finished', iid: merge_request.iid)
      end

      def create_diff_note(merge_request, comment, position, discussion_id = nil)
        attributes = pull_request_comment_attributes(comment)
        attributes.merge!(position: position, type: 'DiffNote')
        attributes[:discussion_id] = discussion_id if discussion_id

        note = merge_request.notes.build(attributes)

        if note.valid?
          note.save
          return note
        end

        log_info(stage: 'create_diff_note', message: 'creating fallback DiffNote', iid: merge_request.iid)

        # Bitbucket Server supports the ability to comment on any line, not just the
        # line in the diff. If we can't add the note as a DiffNote, fallback to creating
        # a regular note.
        create_fallback_diff_note(merge_request, comment, position)
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(
          e,
          stage: 'create_diff_note', comment_id: comment.id, error: e.message
        )

        errors << { type: :pull_request, id: comment.id, errors: e.message }
        nil
      end

      def create_fallback_diff_note(merge_request, comment, position)
        attributes = pull_request_comment_attributes(comment)
        note = "*Comment on"

        note += " #{position.old_path}:#{position.old_line} -->" if position.old_line
        note += " #{position.new_path}:#{position.new_line}" if position.new_line
        note += "*\n\n#{comment.note}"

        attributes[:note] = note
        merge_request.notes.create!(attributes)
      end

      def build_position(merge_request, pr_comment)
        params = {
          diff_refs: merge_request.diff_refs,
          old_path: pr_comment.file_path,
          new_path: pr_comment.file_path,
          old_line: pr_comment.old_pos,
          new_line: pr_comment.new_pos
        }

        Gitlab::Diff::Position.new(params)
      end

      def import_standalone_pr_comments(pr_comments, merge_request)
        pr_comments.each do |comment|
          merge_request.notes.create!(pull_request_comment_attributes(comment))

          comment.comments.each do |replies|
            merge_request.notes.create!(pull_request_comment_attributes(replies))
          end
        rescue StandardError => e
          Gitlab::ErrorTracking.log_exception(
            e,
            stage: 'import_standalone_pr_comments', merge_request_id: merge_request.id, comment_id: comment.id, error: e.message
          )

          errors << { type: :pull_request, comment_id: comment.id, errors: e.message }
        end
      end

      def pull_request_comment_attributes(comment)
        author = find_user_id(comment.author_email)
        note = ''

        unless author
          author = project.creator_id
          note = "*By #{comment.author_username} (#{comment.author_email})*\n\n"
        end

        note +=
          # Provide some context for replying
          if comment.parent_comment
            "> #{comment.parent_comment.note.truncate(80)}\n\n#{comment.note}"
          else
            comment.note
          end

        {
          project: project,
          note: note,
          author_id: author,
          created_at: comment.created_at,
          updated_at: comment.updated_at
        }
      end

      def log_info(details)
        logger.info(log_base_data.merge(details))
      end

      def log_warn(details)
        logger.warn(log_base_data.merge(details))
      end

      def log_base_data
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path
        }
      end
    end
  end
end
