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
                                                    direction: :asc).each do |raw_data|
          pull_request = PullRequest.new(project, raw_data)

          if pull_request.valid?
            merge_request = MergeRequest.create!(pull_request.attributes)
            import_comments_on_pull_request(merge_request, raw_data)
            import_comments_on_pull_request_diff(merge_request, raw_data)
          end
        end
      end

      def import_comments_on_pull_request(merge_request, pull_request)
        client.issue_comments(project.import_source, pull_request.number).each do |raw_data|
          comment = Comment.new(project, raw_data)
          merge_request.notes.create!(comment.attributes)
        end
      end

      def import_comments_on_pull_request_diff(merge_request, pull_request)
        client.pull_request_comments(project.import_source, pull_request.number).each do |raw_data|
          comment = Comment.new(project, raw_data)
          merge_request.notes.create!(comment.attributes)
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
