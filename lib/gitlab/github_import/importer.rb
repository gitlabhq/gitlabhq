module Gitlab
  module GithubImport
    class Importer
      include Gitlab::ShellAdapter

      attr_reader :client, :project, :repo, :repo_url

      def initialize(project)
        @project  = project
        @repo     = project.import_source
        @repo_url = project.import_url

        if credentials
          @client = Client.new(credentials[:user])
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      def execute
        import_labels && import_milestones && import_issues &&
          import_pull_requests && import_wiki
      end

      private

      def credentials
        @credentials ||= project.import_data.credentials if project.import_data
      end

      def import_labels
        labels = client.labels(repo, per_page: 100)
        labels.each { |raw| LabelFormatter.new(project, raw).create! }

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def import_milestones
        milestones = client.milestones(repo, state: :all, per_page: 100)
        milestones.each { |raw| MilestoneFormatter.new(project, raw).create! }

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def import_issues
        issues = client.issues(repo, state: :all, sort: :created, direction: :asc, per_page: 100)

        issues.each do |raw|
          gh_issue = IssueFormatter.new(project, raw)

          if gh_issue.valid?
            issue = gh_issue.create!
            apply_labels(issue)
            import_comments(issue) if gh_issue.has_comments?
          end
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      end

      def import_pull_requests
        pull_requests = client.pull_requests(repo, state: :all, sort: :created, direction: :asc, per_page: 100)
        pull_requests = pull_requests.map { |raw| PullRequestFormatter.new(project, raw) }.select(&:valid?)

        pull_requests.each do |pull_request|
          begin
            restore_source_branch(pull_request) unless pull_request.source_branch_exists?
            restore_target_branch(pull_request) unless pull_request.target_branch_exists?

            merge_request = pull_request.create!
            apply_labels(merge_request)
            import_comments(merge_request)
            import_comments_on_diff(merge_request)
          rescue ActiveRecord::RecordInvalid => e
            raise Projects::ImportService::Error, e.message
          ensure
            clean_up_restored_branches(pull_request)
          end
        end

        true
      end

      def restore_source_branch(pull_request)
        project.repository.fetch_ref(repo_url, "pull/#{pull_request.number}/head", pull_request.source_branch_name)
      end

      def restore_target_branch(pull_request)
        project.repository.create_branch(pull_request.target_branch_name, pull_request.target_branch_sha)
      end

      def remove_branch(name)
        project.repository.delete_branch(name)
      rescue Rugged::ReferenceError
        nil
      end

      def clean_up_restored_branches(pull_request)
        remove_branch(pull_request.source_branch_name) unless pull_request.source_branch_exists?
        remove_branch(pull_request.target_branch_name) unless pull_request.target_branch_exists?

        project.repository.after_remove_branch
      end

      def apply_labels(issuable)
        issue = client.issue(repo, issuable.iid)

        if issue.labels.count > 0
          label_ids = issue.labels.map do |raw|
            Label.find_by(LabelFormatter.new(project, raw).attributes).try(:id)
          end

          issuable.update_attribute(:label_ids, label_ids)
        end
      end

      def import_comments(issuable)
        comments = client.issue_comments(repo, issuable.iid, per_page: 100)
        create_comments(issuable, comments)
      end

      def import_comments_on_diff(merge_request)
        comments = client.pull_request_comments(repo, merge_request.iid, per_page: 100)
        create_comments(merge_request, comments)
      end

      def create_comments(issuable, comments)
        comments.each do |raw|
          comment = CommentFormatter.new(project, raw)
          issuable.notes.create!(comment.attributes)
        end
      end

      def import_wiki
        unless project.wiki_enabled?
          wiki = WikiFormatter.new(project)
          gitlab_shell.import_repository(project.repository_storage_path, wiki.path_with_namespace, wiki.import_url)
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
