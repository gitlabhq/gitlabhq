# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class Importer
      include Gitlab::Utils::StrongMemoize

      PLACEHOLDER_LOAD_SLEEP = 3
      PLACEHOLDER_LOAD_TIMEOUT = 300

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
        unless credentials
          raise Projects::ImportService::Error,
            "Unable to find project import data credentials for project ID: #{@project.id}"
        end

        opts = {}
        # Gitea plan to be GitHub compliant
        if project.gitea_import?
          uri = URI.parse(project.import_url)
          host = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}".sub(%r{/?[\w.-]+/[\w.-]+\.git\z}, '')
          opts = {
            host: host,
            api_version: 'v1'
          }
        end

        @client = Client.new(credentials[:user], **opts)
      end
      strong_memoize_attr :client

      def source_user_mapper
        Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          import_type: project.import_type,
          source_hostname: client.host
        )
      end
      strong_memoize_attr :source_user_mapper

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

        # Gitea doesn't have an API endpoint for pull requests comments
        import_comments(:pull_requests) unless project.gitea_import?

        import_wiki

        # Gitea doesn't have a Release API yet
        # See https://github.com/go-gitea/gitea/issues/330
        # On re-enabling care should be taken to include releases `author_id` field and enable corresponding tests.
        # See:
        # 1) https://gitlab.com/gitlab-org/gitlab/-/issues/343448#note_985979730
        # 2) https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89694/diffs#dfc4a8141aa296465ea3c50b095a30292fb6ebc4_180_182
        import_releases unless project.gitea_import?

        wait_for_placeholder_references
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

        project.import_state.update_column(:last_error, {
          message: 'The remote data could not be fully imported.',
          errors: errors
        }.to_json)
      end

      def import_labels
        fetch_resources(:labels, repo, per_page: 100) do |labels|
          labels.each do |raw|
            gh_label = LabelFormatter.new(project, raw.to_h)
            gh_label.create!
          rescue StandardError => e
            errors << { type: :label, url: Gitlab::UrlSanitizer.sanitize(gh_label.url), errors: e.message }
          end
        end

        cache_labels!
      end

      def import_milestones
        fetch_resources(:milestones, repo, state: :all, per_page: 100) do |milestones|
          milestones.each do |raw|
            gh_milestone = MilestoneFormatter.new(project, raw.to_h)
            gh_milestone.create!
          rescue StandardError => e
            errors << { type: :milestone, url: Gitlab::UrlSanitizer.sanitize(gh_milestone.url), errors: e.message }
          end
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def import_issues
        fetch_resources(:issues, repo, state: :all, sort: :created, direction: :asc, per_page: 100) do |issues|
          issues.each do |raw|
            raw = raw.to_h
            gh_issue = IssueFormatter.new(project, raw, client, source_user_mapper)

            begin
              issuable =
                if gh_issue.pull_request?
                  MergeRequest.find_by(target_project_id: project.id, iid: gh_issue.number)
                else
                  gh_issue.create!
                end

              apply_labels(issuable, raw)
            rescue StandardError => e
              errors << { type: :issue, url: Gitlab::UrlSanitizer.sanitize(gh_issue.url), errors: e.message }
            end
          end
        end

        load_placeholder_references
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def import_pull_requests
        fetch_resources(:pull_requests, repo, state: :all, sort: :created, direction: :asc, per_page: 100) do |prs|
          prs.each do |raw|
            raw = raw.to_h
            gh_pull_request = PullRequestFormatter.new(project, raw, client, source_user_mapper)

            next unless gh_pull_request.valid?

            begin
              restore_source_branch(gh_pull_request) unless gh_pull_request.source_branch_exists?
              restore_target_branch(gh_pull_request) unless gh_pull_request.target_branch_exists?

              merge_request = gh_pull_request.create!

              # Gitea doesn't return PR in the Issue API endpoint, so labels must be assigned at this stage
              apply_labels(merge_request, raw) if project.gitea_import?
            rescue StandardError => e
              errors << {
                type: :pull_request,
                url: Gitlab::UrlSanitizer.sanitize(gh_pull_request.url),
                errors: e.message
              }
            ensure
              clean_up_restored_branches(gh_pull_request)
            end
          end
        end

        project.repository.after_remove_branch
        load_placeholder_references
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
        raw = raw.to_h

        return unless raw[:labels].count > 0

        label_ids = raw[:labels].filter_map { |attrs| @labels[attrs[:name]] }

        issuable.update_attribute(:label_ids, label_ids)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def import_comments(issuable_type)
        resource_type = "#{issuable_type}_comments".to_sym

        # Two notes here:
        # 1. We don't have a distinctive attribute for comments (unlike issues
        # iid), so we fetch the last inserted note, compare it against every
        # comment in the current imported page until we find match, and that's
        # where start importing
        # 2. GH returns comments for _both_ issues and PRs through
        # issues_comments API, while pull_requests_comments returns only
        # comments on diffs, so select last note not based on noteable_type but
        # on line_code
        line_code_is = issuable_type == :pull_requests ? 'NOT NULL' : 'NULL'
        last_note    = project.notes.where("line_code IS #{line_code_is}").last

        fetch_resources(resource_type, repo, per_page: 100) do |comments|
          if last_note
            discard_inserted_comments(comments, last_note)
            last_note = nil
          end

          create_comments(comments)
        end

        load_placeholder_references
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def create_comments(comments)
        ActiveRecord::Base.no_touching do
          comments.each do |raw|
            raw = raw.to_h

            comment = CommentFormatter.new(project, raw, client, source_user_mapper)

            # GH does not return info about comment's parent, so we guess it by checking its URL!
            *_, parent, iid = URI(raw[:html_url]).path.split('/')

            issuable = if parent == 'issues'
                         Issue.find_by(project_id: project.id, iid: iid)
                       else
                         MergeRequest.find_by(target_project_id: project.id, iid: iid)
                       end

            next unless issuable

            comment.gitlab_issuable = issuable
            comment.create!
          rescue StandardError => e
            errors << { type: :comment, url: Gitlab::UrlSanitizer.sanitize(raw[:html_url]), errors: e.message }
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def discard_inserted_comments(comments, last_note)
        last_note_attrs = nil

        cut_off_index = comments.find_index do |raw|
          comment           = CommentFormatter.new(project, raw.to_h)
          comment_attrs     = comment.attributes
          last_note_attrs ||= last_note.slice(*comment_attrs.keys)

          comment_attrs.with_indifferent_access == last_note_attrs
        end

        # No matching resource in the collection, which means we got halted
        # right on the end of the last page, so all good
        return unless cut_off_index

        # Otherwise, remove the resources we've already inserted
        comments.shift(cut_off_index + 1)
      end

      def import_wiki
        return if project.wiki.repository_exists?

        wiki = WikiFormatter.new(project)
        project.wiki.repository.import_repository(wiki.import_url)
      rescue ::Gitlab::Git::CommandError => e
        # GitHub error message when the wiki repo has not been created,
        # this means that repo has wiki enabled, but have no pages. So,
        # we can skip the import.
        errors << { type: :wiki, errors: e.message } if e.message.exclude?('repository not exported')
      end

      def import_releases
        fetch_resources(:releases, repo, per_page: 100) do |releases|
          releases.each do |raw|
            gh_release = ReleaseFormatter.new(project, raw.to_h)
            gh_release.create! if gh_release.valid?
          rescue StandardError => e
            errors << { type: :release, url: Gitlab::UrlSanitizer.sanitize(gh_release.url), errors: e.message }
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
      rescue ::Octokit::NotFound => e
        errors << { type: resource_type, errors: e.message }
      end

      def load_placeholder_references
        return unless project.import_data.user_mapping_enabled?

        ::Import::LoadPlaceholderReferencesWorker.perform_async(
          project.import_type,
          project.import_state.id
        )
      end

      def placeholder_references_loaded?
        return true unless project.import_data.user_mapping_enabled?

        project.placeholder_reference_store.empty?
      end

      def wait_for_placeholder_references
        # Since this importer is synchronous, wait until all placeholder references have been saved
        # to the database before completing the import
        time_waited = 0

        until time_waited >= PLACEHOLDER_LOAD_TIMEOUT || placeholder_references_loaded?
          Kernel.sleep PLACEHOLDER_LOAD_SLEEP
          time_waited += PLACEHOLDER_LOAD_SLEEP
        end

        if placeholder_references_loaded?
          return if time_waited == 0

          ::Import::Framework::Logger.info(
            message: "Placeholder references finished loading to database after #{time_waited} seconds.",
            import_source: project.import_type,
            import_uid: project.import_state.id
          )
        else
          timeout_error = "Timed out after waiting #{PLACEHOLDER_LOAD_TIMEOUT} seconds " \
            "for placeholder references to finish saving"
          errors << { type: :placeholder_references, errors: timeout_error }
        end
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
