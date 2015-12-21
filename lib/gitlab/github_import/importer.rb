module Gitlab
  module GithubImport
    class Importer
      attr_reader :project, :client

      def initialize(project)
        @project = project
        import_data = project.import_data.try(:data)
        github_session = import_data["github_session"] if import_data
        @client = Client.new(github_session["github_access_token"])
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        import_issues
        import_pull_requests

        true
      end

      private

      def import_issues
        # Issues && Comments
        client.list_issues(project.import_source, state: :all,
                                                  sort: :created,
                                                  direction: :asc).each do |issue|
          if issue.pull_request.nil?

            body = @formatter.author_line(issue.user.login)
            body += issue.body || ""

            if issue.comments > 0
              body += @formatter.comments_header

              client.issue_comments(project.import_source, issue.number).each do |c|
                body += @formatter.comment(c.user.login, c.created_at, c.body)
              end
            end

            project.issues.create!(
              description: body,
              title: issue.title,
              state: issue.state == 'closed' ? 'closed' : 'opened',
              author_id: gl_author_id(project, issue.user.id)
            )
          end
        end
      end

      def import_pull_requests
        client.pull_requests(project.import_source, state: :all,
                                                    sort: :created,
                                                    direction: :asc).each do |pull_request|
          source_branch = find_branch(pull_request.head.ref)
          target_branch = find_branch(pull_request.base.ref)

          if source_branch && target_branch
            merge_request = MergeRequest.create!(
              title: pull_request.title,
              description: format_body(pull_request.user.login, pull_request.body),
              source_project: project,
              source_branch: source_branch.name,
              target_project: project,
              target_branch: target_branch.name,
              state: merge_request_state(pull_request),
              author_id: gl_author_id(project, pull_request.user.id),
              assignee_id: gl_user_id(pull_request.assignee.try(:id)),
              created_at: pull_request.created_at,
              updated_at: pull_request.updated_at
            )

            import_comments_on_pull_request(merge_request, pull_request)
            import_comments_on_pull_request_diff(merge_request, pull_request)
          end
        end
      end

      def import_comments_on_pull_request(merge_request, pull_request)
        client.issue_comments(project.import_source, pull_request.number).each do |c|
          merge_request.notes.create!(
            project: project,
            note: format_body(c.user.login, c.body),
            author_id: gl_author_id(project, c.user.id),
            created_at: c.created_at,
            updated_at: c.updated_at
          )
        end
      end

      def import_comments_on_pull_request_diff(merge_request, pull_request)
        client.pull_request_comments(project.import_source, pull_request.number).each do |c|
          merge_request.notes.create!(
            project: project,
            note: format_body(c.user.login, c.body),
            commit_id: c.commit_id,
            line_code: generate_line_code(c.path, c.position),
            author_id: gl_author_id(project, c.user.id),
            created_at: c.created_at,
            updated_at: c.updated_at
          )
        end
      end

      def find_branch(name)
        project.repository.find_branch(name)
      end

      def format_body(author, body)
        @formatter.author_line(author) + (body || "")
      end

      def merge_request_state(pull_request)
        case true
        when pull_request.state == 'closed' && pull_request.merged_at.present?
          'merged'
        when pull_request.state == 'closed'
          'closed'
        else
          'opened'
        end
      end

      def generate_line_code(file_path, position)
        Gitlab::Diff::LineCode.generate(file_path, position, 0)
      end

      def gl_author_id(project, github_id)
        gl_user_id(github_id) || project.creator_id
      end

      def gl_user_id(github_id)
        if github_id
          User.joins(:identities).
            find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s).
            try(:id)
        end
      end
    end
  end
end
