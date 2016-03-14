module Gitlab
  module BitbucketImport
    class Importer
      attr_reader :project, :client

      def initialize(project)
        @project = project
        import_data = project.import_data.try(:data)
        bb_session = import_data["bb_session"] if import_data
        @client = Client.new(bb_session["bitbucket_access_token"],
                             bb_session["bitbucket_access_token_secret"])
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        import_issues if has_issues?

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error.new, e.message
      ensure
        Gitlab::BitbucketImport::KeyDeleter.new(project).execute
      end

      private

      def gl_user_id(project, bitbucket_id)
        if bitbucket_id
          user = User.joins(:identities).find_by("identities.extern_uid = ? AND identities.provider = 'bitbucket'", bitbucket_id.to_s)
          (user && user.id) || project.creator_id
        else
          project.creator_id
        end
      end

      def identifier
        project.import_source
      end

      def has_issues?
        client.project(identifier)["has_issues"]
      end

      def import_issues
        issues = client.issues(identifier)

        issues.each do |issue|
          body = ''
          reporter = nil
          author = 'Anonymous'

          if issue["reported_by"] && issue["reported_by"]["username"]
            reporter = issue["reported_by"]["username"]
            author = reporter
          end

          body = @formatter.author_line(author)
          body += issue["content"]

          comments = client.issue_comments(identifier, issue["local_id"])

          if comments.any?
            body += @formatter.comments_header
          end

          comments.each do |comment|
            author = 'Anonymous'

            if comment["author_info"] && comment["author_info"]["username"]
              author = comment["author_info"]["username"]
            end

            body += @formatter.comment(author, comment["utc_created_on"], comment["content"])
          end

          project.issues.create!(
            description: body,
            title: issue["title"],
            state: %w(resolved invalid duplicate wontfix closed).include?(issue["status"]) ? 'closed' : 'opened',
            author_id: gl_user_id(project, reporter)
          )
        end
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end
    end
  end
end
