module Gitlab
  module BitbucketServerImport
    class Importer
      include Gitlab::ShellAdapter
      attr_reader :project, :project_key, :repository_slug, :client, :errors, :users

      def initialize(project)
        @project = project
        @project_key = project.import_data.data['project_key']
        @repository_slug = project.import_data.data['repo_slug']
        @client = BitbucketServer::Client.new(project.import_data.credentials)
        @formatter = Gitlab::ImportFormatter.new
        @errors = []
        @users = {}
      end

      def execute
        import_pull_requests
        handle_errors

        true
      end

      private

      def handle_errors
        return unless errors.any?

        project.update_column(:import_error, {
          message: 'The remote data could not be fully imported.',
          errors: errors
        }.to_json)
      end

      def gitlab_user_id(project, email)
        find_user_id(email) || project.creator_id
      end

      def find_user_id(email)
        return nil unless email

        return users[email] if users.key?(email)

        users[email] = User.find_by_any_email(email)
      end

      def repo
        @repo ||= client.repo(project_key, repository_slug)
      end

      def import_pull_requests
        pull_requests = client.pull_requests(project_key, repository_slug)

        pull_requests.each do |pull_request|
          begin
            description = ''
            description += @formatter.author_line(pull_request.author) unless find_user_id(pull_request.author_email)
            description += pull_request.description

            source_branch_sha = pull_request.source_branch_sha
            target_branch_sha = pull_request.target_branch_sha
            source_branch_sha = project.repository.commit(source_branch_sha)&.sha || source_branch_sha
            target_branch_sha = project.repository.commit(target_branch_sha)&.sha || target_branch_sha
            project.merge_requests.find_by(iid: pull_request.iid)&.destroy

            merge_request = project.merge_requests.create!(
              iid: pull_request.iid,
              title: pull_request.title,
              description: description,
              source_project: project,
              source_branch: Gitlab::Git.ref_name(pull_request.source_branch_name),
              source_branch_sha: source_branch_sha,
              target_project: project,
              target_branch: Gitlab::Git.ref_name(pull_request.target_branch_name),
              target_branch_sha: target_branch_sha,
              state: pull_request.state,
              author_id: gitlab_user_id(project, pull_request.author_email),
              assignee_id: nil,
              created_at: pull_request.created_at,
              updated_at: pull_request.updated_at
            )

            import_pull_request_comments(pull_request, merge_request) if merge_request.persisted?
          rescue StandardError => e
            errors << { type: :pull_request, iid: pull_request.iid, errors: e.message, trace: e.backtrace.join("\n"), raw_response: pull_request.raw }
          end
        end
      end

      def import_pull_request_comments(pull_request, merge_request)
        # XXX This is inefficient since we are making multiple requests to the activities endpoint
        merge_event = client.activities(project_key, repository_slug, pull_request.iid).find(&:merge_event?)

        import_merge_event(merge_request, merge_event) if merge_event

        comments = client.activities(project_key, repository_slug, pull_request.iid).select(&:comment?)

        inline_comments, pr_comments = comments.partition(&:inline_comment?)

        import_inline_comments(inline_comments.map(&:comment), pull_request, merge_request)
        import_standalone_pr_comments(pr_comments.map(&:comment), merge_request)
      end

      def import_merge_event(merge_request, merge_event)
        committer = merge_event.committer_email

        return unless committer

        user_id = find_user_id(committer) if committer
        timestamp = merge_event.merge_timestamp

        return unless user_id

        event = Event.create(merged_by_id: user_id, merged_at: timestamp)
        MergeRequestMetricsService.new(merge_request.metrics).merge(event)
      end

      def import_inline_comments(inline_comments, pull_request, merge_request)
        inline_comments.each do |comment|
          parent = build_diff_note(merge_request, comment)

          next unless parent&.persisted?

          comment.comments.each do |reply|
            begin
              attributes = pull_request_comment_attributes(reply)
              attributes.merge!(
                position: build_position(merge_request, comment),
                discussion_id: parent.discussion_id,
                type: 'DiffNote')
              merge_request.notes.create!(attributes)
            rescue StandardError => e
              errors << { type: :pull_request, id: comment.id, errors: e.message }
            end
          end
        end
      end

      def build_diff_note(merge_request, comment)
        attributes = pull_request_comment_attributes(comment)
        attributes.merge!(
          position: build_position(merge_request, comment),
          type: 'DiffNote')

        merge_request.notes.create!(attributes)
      rescue StandardError => e
        errors << { type: :pull_request, id: comment.id, errors: e.message }
        nil
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
          begin
            merge_request.notes.create!(pull_request_comment_attributes(comment))

            comment.comments.each do |replies|
              merge_request.notes.create!(pull_request_comment_attributes(replies))
            end
          rescue StandardError => e
            errors << { type: :pull_request, iid: comment.id, errors: e.message }
          end
        end
      end

      def generate_line_code(pr_comment)
        Gitlab::Git.diff_line_code(pr_comment.file_path, pr_comment.new_pos, pr_comment.old_pos)
      end

      def pull_request_comment_attributes(comment)
        {
          project: project,
          note: comment.note,
          author_id: gitlab_user_id(project, comment.author_email),
          created_at: comment.created_at,
          updated_at: comment.updated_at
        }
      end
    end
  end
end
