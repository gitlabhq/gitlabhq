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
          body = @formatter.author_line(pull_request.user.login)
          body += pull_request.body || ""

          source_branch = pull_request.head.ref
          target_branch = pull_request.base.ref

          merge_request = MergeRequest.create!(
            title: pull_request.title,
            description: body,
            source_project: project,
            source_branch: source_branch,
            target_project: project,
            target_branch: target_branch,
            state: merge_request_state(pull_request),
            author_id: gl_author_id(project, pull_request.user.id),
            assignee_id: gl_user_id(pull_request.assignee.try(:id)),
            created_at: pull_request.created_at,
            updated_at: pull_request.updated_at
          )
        end
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
