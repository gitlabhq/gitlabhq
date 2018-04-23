module Gitlab
  module LegacyGithubImport
    class Importer
      include Gitlab::ShellAdapter

      def self.refmap
        Gitlab::GithubImport.refmap
      end

      attr_reader :errors, :project, :repo, :repo_url

      def initialize(project)
        @project  = project
        @repo     = project.import_source
        @repo_url = project.import_url
        @errors   = []
        @labels   = {}
      end

      def client
        return @client if defined?(@client)

        unless credentials
          raise Projects::ImportService::Error,
                "Unable to find project import data credentials for project ID: #{@project.id}"
        end

        opts = {}
        # Gitea plan to be GitHub compliant
        if project.gitea_import?
          uri = URI.parse(project.import_url)
          host = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}".sub(%r{/?[\w-]+/[\w-]+\.git\z}, '')
          opts = {
            host: host,
            api_version: 'v1'
          }
        end

        @client = Client.new(credentials[:user], opts)
      end

      def execute
        # The ordering of importing is important here due to the way GitHub structures their data
        # 1. Labels are required by other items while not having a dependency on anything else
        # so need to be first
        # 2. Pull requests must come before issues. Every pull request is also an issue but not
        # all issues are pull requests. Only the issue entity has labels defined in GitHub. GitLab
        # doesn't structure data like this so we need to make sure that we've created the MRs
        # before we attempt to add the labels defined in the GitHub issue for the related, already
        # imported, pull request
        import_labels
        import_milestones
        import_pull_requests
        import_issues
        import_comments(:issues)
        import_comments(:pull_requests)
        import_wiki

        # Gitea doesn't have a Release API yet
        # See https://github.com/go-gitea/gitea/issues/330
        unless project.gitea_import?
          import_releases
        end

        handle_errors

        true
      end

      private

      def credentials
        return @credentials if defined?(@credentials)

        @credentials = project.import_data ? project.import_data.credentials : nil
      end

      def handle_errors
        return unless errors.any?

        project.update_column(:import_error, {
          message: 'The remote data could not be fully imported.',
          errors: errors
        }.to_json)
      end

      def import_labels
        fetch_resources(:labels, repo, per_page: 100) do |labels|
          labels.each do |raw|
            begin
              gh_label = LabelFormatter.new(project, raw)
              gh_label.create!
            rescue => e
              errors << { type: :label, url: Gitlab::UrlSanitizer.sanitize(gh_label.url), errors: e.message }
            end
          end
        end

        cache_labels!
      end

      def import_milestones
        fetch_resources(:milestones, repo, state: :all, per_page: 100) do |milestones|
          milestones.each do |raw|
            begin
              gh_milestone = MilestoneFormatter.new(project, raw)
              gh_milestone.create!
            rescue => e
              errors << { type: :milestone, url: Gitlab::UrlSanitizer.sanitize(gh_milestone.url), errors: e.message }
            end
          end
        end
      end

      def import_issues
        fetch_resources(:issues, repo, state: :all, sort: :created, direction: :asc, per_page: 100) do |issues|
          issues.each do |raw|
            gh_issue = IssueFormatter.new(project, raw, client)

            begin
              issuable =
                if gh_issue.pull_request?
                  MergeRequest.find_by(target_project_id: project.id, iid: gh_issue.number)
                else
                  gh_issue.create!
                end

              apply_labels(issuable, raw)
            rescue => e
              errors << { type: :issue, url: Gitlab::UrlSanitizer.sanitize(gh_issue.url), errors: e.message }
            end
          end
        end
      end

      def import_pull_requests
        fetch_resources(:pull_requests, repo, state: :all, sort: :created, direction: :asc, per_page: 100) do |pull_requests|
          pull_requests.each do |raw|
            gh_pull_request = PullRequestFormatter.new(project, raw, client)

            next unless gh_pull_request.valid?

            begin
              restore_source_branch(gh_pull_request) unless gh_pull_request.source_branch_exists?
              restore_target_branch(gh_pull_request) unless gh_pull_request.target_branch_exists?

              merge_request = gh_pull_request.create!

              # Gitea doesn't return PR in the Issue API endpoint, so labels must be assigned at this stage
              if project.gitea_import?
                apply_labels(merge_request, raw)
              end
            rescue => e
              errors << { type: :pull_request, url: Gitlab::UrlSanitizer.sanitize(gh_pull_request.url), errors: e.message }
            ensure
              clean_up_restored_branches(gh_pull_request)
            end
          end
        end

        project.repository.after_remove_branch
      end

      def restore_source_branch(pull_request)
        project.repository.create_branch(pull_request.source_branch_name, pull_request.source_branch_sha)
      end

      def restore_target_branch(pull_request)
        project.repository.create_branch(pull_request.target_branch_name, pull_request.target_branch_sha)
      end

      def remove_branch(name)
        project.repository.delete_branch(name)
      rescue Gitlab::Git::Repository::DeleteBranchFailed
        errors << { type: :remove_branch, name: name }
      end

      def clean_up_restored_branches(pull_request)
        return if pull_request.opened?

        remove_branch(pull_request.source_branch_name) unless pull_request.source_branch_exists?
        remove_branch(pull_request.target_branch_name) unless pull_request.target_branch_exists?
      end

      def apply_labels(issuable, raw)
        return unless raw.labels.count > 0

        label_ids = raw.labels
          .map { |attrs| @labels[attrs.name] }
          .compact

        issuable.update_attribute(:label_ids, label_ids)
      end

      def import_comments(issuable_type)
        resource_type = "#{issuable_type}_comments".to_sym

        # Two notes here:
        # 1. We don't have a distinctive attribute for comments (unlike issues iid), so we fetch the last inserted note,
        # compare it against every comment in the current imported page until we find match, and that's where start importing
        # 2. GH returns comments for _both_ issues and PRs through issues_comments API, while pull_requests_comments returns
        # only comments on diffs, so select last note not based on noteable_type but on line_code
        line_code_is = issuable_type == :pull_requests ? 'NOT NULL' : 'NULL'
        last_note    = project.notes.where("line_code IS #{line_code_is}").last

        fetch_resources(resource_type, repo, per_page: 100) do |comments|
          if last_note
            discard_inserted_comments(comments, last_note)
            last_note = nil
          end

          create_comments(comments)
        end
      end

      def create_comments(comments)
        ActiveRecord::Base.no_touching do
          comments.each do |raw|
            begin
              comment = CommentFormatter.new(project, raw, client)

              # GH does not return info about comment's parent, so we guess it by checking its URL!
              *_, parent, iid = URI(raw.html_url).path.split('/')

              issuable = if parent == 'issues'
                           Issue.find_by(project_id: project.id, iid: iid)
                         else
                           MergeRequest.find_by(target_project_id: project.id, iid: iid)
                         end

              next unless issuable

              issuable.notes.create!(comment.attributes)
            rescue => e
              errors << { type: :comment, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end
        end
      end

      def discard_inserted_comments(comments, last_note)
        last_note_attrs = nil

        cut_off_index = comments.find_index do |raw|
          comment           = CommentFormatter.new(project, raw)
          comment_attrs     = comment.attributes
          last_note_attrs ||= last_note.slice(*comment_attrs.keys)

          comment_attrs.with_indifferent_access == last_note_attrs
        end

        # No matching resource in the collection, which means we got halted right on the end of the last page, so all good
        return unless cut_off_index

        # Otherwise, remove the resources we've already inserted
        comments.shift(cut_off_index + 1)
      end

      def import_wiki
        unless project.wiki.repository_exists?
          wiki = WikiFormatter.new(project)
          gitlab_shell.import_repository(project.repository_storage, wiki.disk_path, wiki.import_url)
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
        fetch_resources(:releases, repo, per_page: 100) do |releases|
          releases.each do |raw|
            begin
              gh_release = ReleaseFormatter.new(project, raw)
              gh_release.create! if gh_release.valid?
            rescue => e
              errors << { type: :release, url: Gitlab::UrlSanitizer.sanitize(gh_release.url), errors: e.message }
            end
          end
        end
      end

      def cache_labels!
        project.labels.select(:id, :title).find_each do |label|
          @labels[label.title] = label.id
        end
      end

      def fetch_resources(resource_type, *opts)
        return if imported?(resource_type)

        opts.last[:page] = current_page(resource_type)

        client.public_send(resource_type, *opts) do |resources| # rubocop:disable GitlabSecurity/PublicSend
          yield resources
          increment_page(resource_type)
        end

        imported!(resource_type)
      end

      def imported?(resource_type)
        Rails.cache.read("#{cache_key_prefix}:#{resource_type}:imported")
      end

      def imported!(resource_type)
        Rails.cache.write("#{cache_key_prefix}:#{resource_type}:imported", true, ex: 1.day)
      end

      def increment_page(resource_type)
        key = "#{cache_key_prefix}:#{resource_type}:current-page"

        # Rails.cache.increment calls INCRBY directly on the value stored under the key, which is
        # a serialized ActiveSupport::Cache::Entry, so it will return an error by Redis, hence this ugly work-around
        page = Rails.cache.read(key)
        page += 1
        Rails.cache.write(key, page)

        page
      end

      def current_page(resource_type)
        Rails.cache.fetch("#{cache_key_prefix}:#{resource_type}:current-page", ex: 1.day) { 1 }
      end

      def cache_key_prefix
        @cache_key_prefix ||= "github-import:#{project.id}"
      end
    end
  end
end
