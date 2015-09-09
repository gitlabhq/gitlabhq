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
        #Issues && Comments
        client.list_issues(project.import_source, state: :all,
                                                  sort: :created,
                                                  direction: :asc).each do |issue|
          if issue.pull_request.nil?

            body = @formatter.author_line(issue.user.login)
            body += issue.body

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
              author_id: gl_user_id(project, issue.user.id)
            )
          end
        end
      end

      private

      def gl_user_id(project, github_id)
        user = User.joins(:identities).
          find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s)
        (user && user.id) || project.creator_id
      end
    end
  end
end
