module Gitlab
  module BitbucketImport
    class Importer
      attr_reader :project, :client

      def initialize(project)
        @project = project
        @client = Client.new(project.creator.bitbucket_access_token, project.creator.bitbucket_access_token_secret)
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        project_identifier = project.import_source

        return true unless client.project(project_identifier)["has_issues"]

        #Issues && Comments
        issues = client.issues(project_identifier)
        
        issues["issues"].each do |issue|
          body = @formatter.author_line(issue["reported_by"]["username"], issue["content"])
          
          comments = client.issue_comments(project_identifier, issue["local_id"])
          
          if comments.any?
            body += @formatter.comments_header
          end

          comments.each do |comment|
            body += @formatter.comment(comment["author_info"]["username"], comment["utc_created_on"], comment["content"])
          end

          project.issues.create!(
            description: body, 
            title: issue["title"],
            state: %w(resolved invalid duplicate wontfix).include?(issue["status"]) ? 'closed' : 'opened',
            author_id: gl_user_id(project, issue["reported_by"]["username"])
          )
        end
        
        true
      end

      private

      def gl_user_id(project, bitbucket_id)
        user = User.joins(:identities).find_by("identities.extern_uid = ? AND identities.provider = 'bitbucket'", bitbucket_id.to_s)
        (user && user.id) || project.creator_id
      end
    end
  end
end
