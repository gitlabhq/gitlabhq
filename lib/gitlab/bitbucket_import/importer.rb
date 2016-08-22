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
            author_id: gl_user_id(project, issue.author),
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
                author_id: gl_user_id(project, comment.author),
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
    end
  end
end
