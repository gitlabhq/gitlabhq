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
        disable_webhooks

        pull_requests = client.pull_requests(repo, state: :all, sort: :created, direction: :asc, per_page: 100)
        pull_requests = pull_requests.map { |raw| PullRequestFormatter.new(project, raw) }.select(&:valid?)

        source_branches_removed = pull_requests.reject(&:source_branch_exists?).map { |pr| [pr.source_branch_name, pr.source_branch_sha] }
        target_branches_removed = pull_requests.reject(&:target_branch_exists?).map { |pr| [pr.target_branch_name, pr.target_branch_sha] }
        branches_removed = source_branches_removed | target_branches_removed

        restore_branches(branches_removed)

        pull_requests.each do |pull_request|
          merge_request = pull_request.create!
          apply_labels(merge_request)
          import_comments(merge_request)
          import_comments_on_diff(merge_request)
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        raise Projects::ImportService::Error, e.message
      ensure
        clean_up_restored_branches(branches_removed)
        clean_up_disabled_webhooks
      end

      def disable_webhooks
        update_webhooks(hooks, active: false)
      end

      def clean_up_disabled_webhooks
        update_webhooks(hooks, active: true)
      end

      def update_webhooks(hooks, options)
        hooks.each do |hook|
          client.edit_hook(repo, hook.id, hook.name, hook.config, options)
        end
      end

      def hooks
        @hooks ||=
          begin
            client.hooks(repo).map { |raw| HookFormatter.new(raw) }.select(&:valid?)

          # The GitHub Repository Webhooks API returns 404 for users
          # without admin access to the repository when listing hooks.
          # In this case we just want to return gracefully instead of
          # spitting out an error and stop the import process.
          rescue Octokit::NotFound
            []
          end
      end

      def restore_branches(branches)
        branches.each do |name, sha|
          client.create_ref(repo, "refs/heads/#{name}", sha)
        end

        project.repository.fetch_ref(repo_url, '+refs/heads/*', 'refs/heads/*')
      end

      def clean_up_restored_branches(branches)
        branches.each do |name, _|
          client.delete_ref(repo, "heads/#{name}")
          project.repository.delete_branch(name) rescue Rugged::ReferenceError
        end

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
