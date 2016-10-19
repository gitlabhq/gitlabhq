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
        import_labels        unless imported?(:labels)
        import_milestones    unless imported?(:milestones)
        import_issues        unless imported?(:issues)
        import_pull_requests unless imported?(:pull_requests)
        import_comments
        import_wiki
        import_releases      unless imported?(:releases)
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
        client.labels(repo, page: current_page(:labels), per_page: 100) do |labels|
          labels.each do |raw|
            begin
              label = LabelFormatter.new(project, raw).create!
              @labels[label.title] = label.id
            rescue => e
              errors << { type: :label, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end

          increment_page(:labels)
        end

        imported!(:labels)
      end

      def import_milestones
        client.milestones(repo, state: :all, page: current_page(:milestones), per_page: 100) do |milestones|
          milestones.each do |raw|
            begin
              MilestoneFormatter.new(project, raw).create!
            rescue => e
              errors << { type: :milestone, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end

          increment_page(:milestones)
        end

        imported!(:milestones)
      end

      def import_issues
        client.issues(repo, state: :all, sort: :created, direction: :asc, page: current_page(:issues), per_page: 100) do |issues|
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

          increment_page(:issues)
        end

        imported!(:issues)
      end

      def import_pull_requests
        client.pull_requests(repo, state: :all, sort: :created, direction: :asc, page: current_page(:pull_requests), per_page: 100) do |pull_requests|
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

          increment_page(:pull_requests)
        end

        project.repository.after_remove_branch

        imported!(:pull_requests)
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
        # GH returns labels for issues but not for pull requests!
        labels = if issuable.is_a?(MergeRequest)
                   client.labels_for_issue(repo, raw_issuable.number)
                 else
                   raw_issuable.labels
                 end

        if labels.count > 0
          label_ids = labels
            .map { |attrs| @labels[attrs.name] }
            .compact

          issuable.update_attribute(:label_ids, label_ids)
        end
      end

      def import_comments
        # We don't have a distinctive attribute for comments (unlike issues iid), so we fetch the last inserted note,
        # compare it against every comment in the current imported page until we find match, and that's where start importing
        last_note = Note.where(noteable_type: 'Issue').last

        client.issues_comments(repo, page: current_page(:issue_comments), per_page: 100) do |comments|
          if last_note
            discard_inserted_comments(comments, last_note)
            last_note = nil
          end

          create_comments(comments)
          increment_page(:issue_comments)
        end unless imported?(:issue_comments)

        imported!(:issue_comments)

        last_note = Note.where(noteable_type: 'MergeRequest').last
        client.pull_requests_comments(repo, page: current_page(:pull_request_comments), per_page: 100) do |comments|
          if last_note
            discard_inserted_comments(comments, last_note)
            last_note = nil
          end

          create_comments(comments)
          increment_page(:pull_request_comments)
        end unless imported?(:pull_request_comments)

        imported!(:pull_request_comments)
      end

      def create_comments(comments)
        ActiveRecord::Base.no_touching do
          comments.each do |raw|
            begin
              comment         = CommentFormatter.new(project, raw)
              # GH does not return info about comment's parent, so we guess it by checking its URL!
              *_, parent, iid = URI(raw.html_url).path.split('/')
              issuable_class = parent == 'issues' ? Issue : MergeRequest
              issuable       = issuable_class.find_by_iid(iid)
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

        # Otherwise, remove the resouces we've already inserted
        comments.shift(cut_off_index + 1)
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
        client.releases(repo, page: current_page(:releases), per_page: 100) do |releases|
          releases.each do |raw|
            begin
              gh_release = ReleaseFormatter.new(project, raw)
              gh_release.create! if gh_release.valid?
            rescue => e
              errors << { type: :release, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end

          increment_page(:releases)
        end

        imported!(:releases)
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
