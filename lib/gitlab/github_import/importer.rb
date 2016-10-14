module Gitlab
  module GithubImport
    class Importer
      include Gitlab::ShellAdapter

      attr_reader :client, :errors, :project, :repo, :repo_url

      def initialize(project)
        @project  = project
        @repo     = project.import_source
        @repo_url = project.import_url
        @errors   = []
        @labels   = {}

        if credentials
          @client = Client.new(credentials[:user])
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      def execute
        import_labels
        import_milestones
        import_issues
        import_pull_requests
        import_comments
        import_wiki
        import_releases
        handle_errors

        true
      end

      private

      def credentials
        @credentials ||= project.import_data.credentials if project.import_data
      end

      def handle_errors
        return unless errors.any?

        project.update_column(:import_error, {
          message: 'The remote data could not be fully imported.',
          errors: errors
        }.to_json)
      end

      def import_labels
        client.labels(repo, per_page: 100) do |labels|
          labels.each do |raw|
            begin
              label = LabelFormatter.new(project, raw).create!
              @labels[label.title] = label.id
            rescue => e
              errors << { type: :label, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end
        end
      end

      def import_milestones
        client.milestones(repo, state: :all, per_page: 100) do |milestones|
          milestones.each do |raw|
            begin
              MilestoneFormatter.new(project, raw).create!
            rescue => e
              errors << { type: :milestone, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end
        end
      end

      def import_issues
        client.issues(repo, state: :all, sort: :created, direction: :asc, per_page: 100) do |issues|
          issues.each do |raw|
            gh_issue = IssueFormatter.new(project, raw)

            if gh_issue.valid?
              begin
                issue = gh_issue.create!
                apply_labels(issue, raw)
              rescue => e
                errors << { type: :issue, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
              end
            end
          end
        end
      end

      def import_pull_requests
        client.pull_requests(repo, state: :all, sort: :created, direction: :asc, per_page: 100) do |pull_requests|
          pull_requests.each do |raw|
            pull_request = PullRequestFormatter.new(project, raw)
            next unless pull_request.valid?

            begin
              restore_source_branch(pull_request) unless pull_request.source_branch_exists?
              restore_target_branch(pull_request) unless pull_request.target_branch_exists?

              merge_request = pull_request.create!
              apply_labels(merge_request, raw)
            rescue => e
              errors << { type: :pull_request, url: Gitlab::UrlSanitizer.sanitize(pull_request.url), errors: e.message }
            ensure
              clean_up_restored_branches(pull_request)
            end
          end
        end

        project.repository.after_remove_branch
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
        errors << { type: :remove_branch, name: name }
      end

      def clean_up_restored_branches(pull_request)
        remove_branch(pull_request.source_branch_name) unless pull_request.source_branch_exists?
        remove_branch(pull_request.target_branch_name) unless pull_request.target_branch_exists?
      end

      def apply_labels(issuable, raw_issuable)
        if raw_issuable.labels.count > 0
          label_ids = raw_issuable.labels
            .map { |attrs| @labels[attrs.name] }
            .compact

          issuable.update_attribute(:label_ids, label_ids)
        end
      end

      def import_comments
        client.issues_comments(repo, per_page: 100) do |comments|
          create_comments(comments, :issue)
        end

        client.pull_requests_comments(repo, per_page: 100) do |comments|
          create_comments(comments, :pull_request)
        end
      end

      def create_comments(comments, issuable_type)
        ActiveRecord::Base.no_touching do
          comments.each do |raw|
            begin
              comment        = CommentFormatter.new(project, raw)
              issuable_class = issuable_type == :issue ? Issue : MergeRequest
              iid            = raw.send("#{issuable_type}_url").split('/').last # GH doesn't return parent ID directly
              issuable       = issuable_class.find_by_iid(iid)
              next unless issuable

              issuable.notes.create!(comment.attributes)
            rescue => e
              errors << { type: :comment, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end
        end
      end

      def import_wiki
        unless project.wiki.repository_exists?
          wiki = WikiFormatter.new(project)
          gitlab_shell.import_repository(project.repository_storage_path, wiki.path_with_namespace, wiki.import_url)
        end
      rescue Gitlab::Shell::Error => e
        # GitHub error message when the wiki repo has not been created,
        # this means that repo has wiki enabled, but have no pages. So,
        # we can skip the import.
        if e.message !~ /repository not exported/
          errors << { type: :wiki, errors: e.message }
        end
      end

      def import_releases
        client.releases(repo, per_page: 100) do |releases|
          releases.each do |raw|
            begin
              gh_release = ReleaseFormatter.new(project, raw)
              gh_release.create! if gh_release.valid?
            rescue => e
              errors << { type: :release, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end
        end
      end
    end
  end
end
