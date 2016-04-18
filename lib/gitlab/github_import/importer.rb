module Gitlab
  module GithubImport
    class Importer
      include Gitlab::ShellAdapter

      attr_reader :project, :client

      def initialize(project)
        @project = project
        if import_data_credentials
          @client = Client.new(import_data_credentials[:user])
          @formatter = Gitlab::ImportFormatter.new
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      def execute
        import_labels && import_milestones && import_issues &&
          import_pull_requests && import_wiki
      end

      private

      def import_data_credentials
        @import_data_credentials ||= project.import_data.credentials if project.import_data
      end

      def import_labels
        client.labels(project.import_source).each do |raw_data|
          Label.create!(LabelFormatter.new(project, raw_data).attributes)
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def import_milestones
        client.list_milestones(project.import_source, state: :all).each do |raw_data|
          Milestone.create!(MilestoneFormatter.new(project, raw_data).attributes)
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def import_issues
        client.list_issues(project.import_source, state: :all,
                                                  sort: :created,
                                                  direction: :asc).each do |raw_data|
          gh_issue = IssueFormatter.new(project, raw_data)

          if gh_issue.valid?
            issue = Issue.create!(gh_issue.attributes)
            apply_labels(gh_issue.number, issue)

            if gh_issue.has_comments?
              import_comments(gh_issue.number, issue)
            end
          end
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def import_pull_requests
        client.pull_requests(project.import_source, state: :all,
                                                    sort: :created,
                                                    direction: :asc).each do |raw_data|
          pull_request = PullRequestFormatter.new(project, raw_data)

          if pull_request.valid?
            merge_request = MergeRequest.new(pull_request.attributes)

            if merge_request.save
              apply_labels(pull_request.number, merge_request)
              import_comments(pull_request.number, merge_request)
              import_comments_on_diff(pull_request.number, merge_request)
            end
          end
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def apply_labels(number, issuable)
        issue = client.issue(project.import_source, number)

        if issue.labels.count > 0
          label_ids = issue.labels.map do |raw|
            Label.find_by(LabelFormatter.new(project, raw).attributes).try(:id)
          end

          issuable.update_attribute(:label_ids, label_ids)
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

        true
      rescue Gitlab::Shell::Error => e
        # GitHub error message when the wiki repo has not been created,
        # this means that repo has wiki enabled, but have no pages. So,
        # we can skip the import.
        if e.message !~ /repository not exported/
          raise Projects::ImportService::Error, e.message
        else
          true
        end
      end
    end
  end
end
