module Gitlab
  module GithubImport
    class Importer
      include Gitlab::ShellAdapter

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
        import_wiki

        true
      rescue Gitlab::Shell::Error
        false
      end

      private

      def import_issues
        client.list_issues(project.import_source, state: :all,
                                                  sort: :created,
                                                  direction: :asc).each do |raw_data|
          gh_issue = IssueFormatter.new(project, raw_data)

          if gh_issue.valid?
            issue = Issue.create!(gh_issue.attributes)

            if gh_issue.has_comments?
              import_comments(gh_issue.number, issue)
            end
          end
        end
      end

      def import_pull_requests
        client.pull_requests(project.import_source, state: :all,
                                                    sort: :created,
                                                    direction: :asc).each do |raw_data|
          pull_request = PullRequestFormatter.new(project, raw_data)

          if !pull_request.cross_project? && pull_request.valid?
            merge_request = MergeRequest.create!(pull_request.attributes)
            import_comments(pull_request.number, merge_request)
            import_comments_on_diff(pull_request.number, merge_request)
          end
        end
      end

      def import_comments(issue_number, noteable)
        comments = client.issue_comments(project.import_source, issue_number)
        create_comments(comments, noteable)
      end

      def import_comments_on_diff(pull_request_number, merge_request)
        comments = client.pull_request_comments(project.import_source, pull_request_number)
        create_comments(comments, merge_request)
      end

      def create_comments(comments, noteable)
        comments.each do |raw_data|
          comment = CommentFormatter.new(project, raw_data)
          noteable.notes.create!(comment.attributes)
        end
      end

      def import_wiki
        unless project.wiki_enabled?
          wiki = WikiFormatter.new(project)
          gitlab_shell.import_repository(wiki.path_with_namespace, wiki.import_url)
          project.update_attribute(:wiki_enabled, true)
        end
      end
    end
  end
end
