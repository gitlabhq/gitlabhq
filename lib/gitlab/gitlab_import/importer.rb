# frozen_string_literal: true

module Gitlab
  module GitlabImport
    class Importer
      attr_reader :project, :client

      def initialize(project)
        @project = project
        import_data = project.import_data
        if import_data && import_data.credentials && import_data.credentials[:password]
          @client = Client.new(import_data.credentials[:password])
          @formatter = Gitlab::ImportFormatter.new
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      def execute
        ActiveRecord::Base.no_touching do
          project_identifier = CGI.escape(project.import_source)

          # Issues && Comments
          issues = client.issues(project_identifier)

          issues.each do |issue|
            body = [@formatter.author_line(issue["author"]["name"])]
            body << issue["description"]

            comments = client.issue_comments(project_identifier, issue["iid"])

            if comments.any?
              body << @formatter.comments_header
            end

            comments.each do |comment|
              body << @formatter.comment(comment["author"]["name"], comment["created_at"], comment["body"])
            end

            project.issues.create!(
              iid: issue["iid"],
              description: body.join,
              title: issue["title"],
              state: issue["state"],
              updated_at: issue["updated_at"],
              author_id: gitlab_user_id(project, issue["author"]["id"]),
              confidential: issue["confidential"]
            )
          end
        end

        true
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def gitlab_user_id(project, gitlab_id)
        user_id = User.by_provider_and_extern_uid(:gitlab, gitlab_id).select(:id).first&.id
        user_id || project.creator_id
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
