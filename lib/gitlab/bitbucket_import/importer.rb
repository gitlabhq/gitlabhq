module Gitlab
  module BitbucketImport
    class Importer
      attr_reader :project, :client

      def initialize(project)
        @project = project
        @client = Bitbucket::Client.new(project.import_data.credentials)
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        import_issues
        import_pull_requests

        true
      end

      private

      def gitlab_user_id(project, bitbucket_id)
        if bitbucket_id
          user = User.joins(:identities).find_by("identities.extern_uid = ? AND identities.provider = 'bitbucket'", bitbucket_id.to_s)
          (user && user.id) || project.creator_id
        else
          project.creator_id
        end
      end

      def repo
        @repo ||= client.repo(project.import_source)
      end

      def import_issues
        return unless repo.has_issues?

        client.issues(repo).each do |issue|
          description = @formatter.author_line(issue.author)
          description += issue.description

          issue = project.issues.create(
            iid: issue.iid,
            title: issue.title,
            description: description,
            state: issue.state,
            author_id: gitlab_user_id(project, issue.author),
            created_at: issue.created_at,
            updated_at: issue.updated_at
          )

          if issue.persisted?
            client.issue_comments(repo, issue.iid).each do |comment|
              note = @formatter.author_line(comment.author)
              note += comment.note

              issue.notes.create!(
                project: project,
                note: note,
                author_id: gitlab_user_id(project, comment.author),
                created_at: comment.created_at,
                updated_at: comment.updated_at
              )
            end
          end

          project.issues.create!(
            description: body,
            title: issue["title"],
            state: %w(resolved invalid duplicate wontfix closed).include?(issue["status"]) ? 'closed' : 'opened',
            author_id: gitlab_user_id(project, reporter)
          )
        end
      rescue ActiveRecord::RecordInvalid
        nil
      end

      def import_pull_requests
        pull_requests = client.pull_requests(repo)

        pull_requests.each do |pull_request|
          begin
            description = @formatter.author_line(pull_request.author)
            description += pull_request.description

            merge_request = project.merge_requests.create(
              iid: pull_request.iid,
              title: pull_request.title,
              description: description,
              source_project: project,
              source_branch: pull_request.source_branch_name,
              source_branch_sha: pull_request.source_branch_sha,
              target_project: project,
              target_branch: pull_request.target_branch_name,
              target_branch_sha: pull_request.target_branch_sha,
              state: pull_request.state,
              author_id: gitlab_user_id(project, pull_request.author),
              assignee_id: nil,
              created_at: pull_request.created_at,
              updated_at: pull_request.updated_at
            )

            import_pull_request_comments(pull_request, merge_request) if merge_request.persisted?
          rescue ActiveRecord::RecordInvalid
            nil
          end
        end
      end

      def import_pull_request_comments(pull_request, merge_request)
        comments = client.pull_request_comments(repo, pull_request.iid)

        inline_comments, pr_comments = comments.partition(&:inline?)

        import_inline_comments(inline_comments, pull_request, merge_request)
        import_standalone_pr_comments(pr_comments, merge_request)
      end

      def import_inline_comments(inline_comments, pull_request, merge_request)
        line_code_map = {}

        children, parents = inline_comments.partition(&:has_parent?)

        # The Bitbucket API returns threaded replies as parent-child
        # relationships. We assume that the child can appear in any order in
        # the JSON.
        parents.each do |comment|
          line_code_map[comment.iid] = generate_line_code(comment)
        end

        children.each do |comment|
          line_code_map[comment.iid] = line_code_map.fetch(comment.parent_id, nil)
        end

        inline_comments.each do |comment|
          begin
            attributes = pull_request_comment_attributes(comment)
            attributes.merge!(
              commit_id: pull_request.source_branch_sha,
              line_code: line_code_map.fetch(comment.iid),
              type: 'LegacyDiffNote')

            note = merge_request.notes.create!(attributes)
          rescue ActiveRecord::RecordInvalid => e
            Rails.log.error("Bitbucket importer ERROR: Invalid pull request comment #{e.message}")
            nil
          end
        end
      end

      def import_standalone_pr_comments(pr_comments, merge_request)
        pr_comments.each do |comment|
          begin
            merge_request.notes.create!(pull_request_comment_attributes(comment))
          rescue ActiveRecord::RecordInvalid => e
            Rails.log.error("Bitbucket importer ERROR: Invalid standalone pull request comment #{e.message}")
            nil
          end
        end
      end

      def generate_line_code(pr_comment)
        Gitlab::Diff::LineCode.generate(pr_comment.file_path, pr_comment.new_pos, pr_comment.old_pos)
      end

      def pull_request_comment_attributes(comment)
        {
          project: project,
          note: comment.note,
          author_id: gitlab_user_id(project, comment.author),
          created_at: comment.created_at,
          updated_at: comment.updated_at
        }
      end
    end
  end
end
