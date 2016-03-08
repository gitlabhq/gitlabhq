module Gitlab
  module GitlabImport
    class Importer
      attr_reader :project, :client

      def initialize(project)
        @project = project
        import_data = project.import_data.try(:data)
        gitlab_session = import_data["gitlab_session"] if import_data
        @client = Client.new(gitlab_session["gitlab_access_token"])
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        project_identifier = CGI.escape(project.import_source)

        #Issues && Comments
        issues = client.issues(project_identifier)

        issues.each do |issue|
          body = @formatter.author_line(issue["author"]["name"])
          body += issue["description"]

          comments = client.issue_comments(project_identifier, issue["id"])

          if comments.any?
            body += @formatter.comments_header
          end

          comments.each do |comment|
            body += @formatter.comment(comment["author"]["name"], comment["created_at"], comment["body"])
          end

          project.issues.create!(
            description: body,
            title: issue["title"],
            state: issue["state"],
            author_id: gl_user_id(project, issue["author"]["id"])
          )
        end

        true
      end

      private

      def gl_user_id(project, gitlab_id)
        user = User.joins(:identities).find_by("identities.extern_uid = ? AND identities.provider = 'gitlab'", gitlab_id.to_s)
        (user && user.id) || project.creator_id
      end
    end
  end
end
