require_relative 'error'
require_relative 'import/issue'
require_relative 'import/legacy_diff_note'
require_relative 'import/merge_request'
require_relative 'import/note'

module Github
  class Import
    include Gitlab::ShellAdapter

    attr_reader :project, :repository, :repo, :repo_url, :wiki_url,
                :options, :errors, :cached, :verbose, :last_fetched_at

    def initialize(project, options = {})
      @project = project
      @repository = project.repository
      @repo = project.import_source
      @repo_url = project.import_url
      @wiki_url = project.import_url.sub(/\.git\z/, '.wiki.git')
      @options = options.reverse_merge(token: project.import_data&.credentials&.fetch(:user))
      @verbose = options.fetch(:verbose, false)
      @cached  = Hash.new { |hash, key| hash[key] = Hash.new }
      @errors  = []
      @last_fetched_at = nil
    end

    # rubocop: disable Rails/Output
    def execute
      puts 'Fetching repository...'.color(:aqua) if verbose
      setup_and_fetch_repository
      puts 'Fetching labels...'.color(:aqua) if verbose
      fetch_labels
      puts 'Fetching milestones...'.color(:aqua) if verbose
      fetch_milestones
      puts 'Fetching pull requests...'.color(:aqua) if verbose
      fetch_pull_requests
      puts 'Fetching issues...'.color(:aqua) if verbose
      fetch_issues
      puts 'Fetching releases...'.color(:aqua) if verbose
      fetch_releases
      puts 'Cloning wiki repository...'.color(:aqua) if verbose
      fetch_wiki_repository
      puts 'Expiring repository cache...'.color(:aqua) if verbose
      expire_repository_cache

      errors.empty?
    rescue Github::RepositoryFetchError
      expire_repository_cache
      false
    ensure
      keep_track_of_errors
    end

    private

    def setup_and_fetch_repository
      begin
        project.ensure_repository
        project.repository.add_remote('github', repo_url)
        project.repository.set_import_remote_as_mirror('github')
        project.repository.add_remote_fetch_config('github', '+refs/pull/*/head:refs/merge-requests/*/head')
        fetch_remote(forced: true)
      rescue Gitlab::Git::Repository::NoRepository, Gitlab::Shell::Error => e
        error(:project, repo_url, e.message)
        raise Github::RepositoryFetchError
      end
    end

    def fetch_remote(forced: false)
      @last_fetched_at = Time.now
      project.repository.fetch_remote('github', forced: forced)
    end

    def fetch_wiki_repository
      return if project.wiki.repository_exists?

      wiki_path = project.wiki.disk_path
      gitlab_shell.import_repository(project.repository_storage_path, wiki_path, wiki_url)
    rescue Gitlab::Shell::Error => e
      # GitHub error message when the wiki repo has not been created,
      # this means that repo has wiki enabled, but have no pages. So,
      # we can skip the import.
      if e.message !~ /repository not exported/
        error(:wiki, wiki_url, e.message)
      end
    end

    def fetch_labels
      url = "/repos/#{repo}/labels"

      while url
        response = Github::Client.new(options).get(url)

        response.body.each do |raw|
          begin
            representation = Github::Representation::Label.new(raw)

            label = project.labels.find_or_create_by!(title: representation.title) do |label|
              label.color = representation.color
            end

            cached[:label_ids][representation.title] = label.id
          rescue => e
            error(:label, representation.url, e.message)
          end
        end

        url = response.rels[:next]
      end
    end

    def fetch_milestones
      url = "/repos/#{repo}/milestones"

      while url
        response = Github::Client.new(options).get(url, state: :all)

        response.body.each do |raw|
          begin
            milestone = Github::Representation::Milestone.new(raw)
            next if project.milestones.where(iid: milestone.iid).exists?

            project.milestones.create!(
              iid: milestone.iid,
              title: milestone.title,
              description: milestone.description,
              due_date: milestone.due_date,
              state: milestone.state,
              created_at: milestone.created_at,
              updated_at: milestone.updated_at
            )
          rescue => e
            error(:milestone, milestone.url, e.message)
          end
        end

        url = response.rels[:next]
      end
    end

    def fetch_pull_requests
      url = "/repos/#{repo}/pulls"

      while url
        response = Github::Client.new(options).get(url, state: :all, sort: :created, direction: :asc)

        response.body.each do |raw|
          pull_request  = Github::Representation::PullRequest.new(raw, options.merge(project: project))
          merge_request = MergeRequest.find_or_initialize_by(iid: pull_request.iid, source_project_id: project.id)
          next unless merge_request.new_record? && pull_request.valid?

          begin
            # If the PR has been created/updated after we last fetched the
            # remote, we fetch again to get the up-to-date refs.
            fetch_remote if pull_request.updated_at > last_fetched_at

            author_id   = user_id(pull_request.author, project.creator_id)
            description = format_description(pull_request.description, pull_request.author)

            merge_request.attributes = {
              iid: pull_request.iid,
              title: pull_request.title,
              description: description,
              ref_fetched: true,
              source_project: pull_request.source_project,
              source_branch: pull_request.source_branch_name,
              source_branch_sha: pull_request.source_branch_sha,
              target_project: pull_request.target_project,
              target_branch: pull_request.target_branch_name,
              target_branch_sha: pull_request.target_branch_sha,
              state: pull_request.state,
              milestone_id: milestone_id(pull_request.milestone),
              author_id: author_id,
              assignee_id: user_id(pull_request.assignee),
              created_at: pull_request.created_at,
              updated_at: pull_request.updated_at
            }

            merge_request.save!(validate: false)
            merge_request.merge_request_diffs.create

            review_comments_url = "/repos/#{repo}/pulls/#{pull_request.iid}/comments"
            fetch_comments(merge_request, :review_comment, review_comments_url, LegacyDiffNote)
          rescue => e
            error(:pull_request, pull_request.url, e.message)
          end
        end

        url = response.rels[:next]
      end
    end

    def fetch_issues
      url = "/repos/#{repo}/issues"

      while url
        response = Github::Client.new(options).get(url, state: :all, sort: :created, direction: :asc)

        response.body.each { |raw| populate_issue(raw) }

        url = response.rels[:next]
      end
    end

    def populate_issue(raw)
      representation = Github::Representation::Issue.new(raw, options)

      begin
        # Every pull request is an issue, but not every issue
        # is a pull request. For this reason, "shared" actions
        # for both features, like manipulating assignees, labels
        # and milestones, are provided within the Issues API.
        if representation.pull_request?
          return unless representation.labels? || representation.comments?

          merge_request = MergeRequest.find_by!(target_project_id: project.id, iid: representation.iid)

          if representation.labels?
            merge_request.update_attribute(:label_ids, label_ids(representation.labels))
          end

          fetch_comments_conditionally(merge_request, representation)
        else
          return if Issue.exists?(iid: representation.iid, project_id: project.id)

          author_id          = user_id(representation.author, project.creator_id)
          issue              = Issue.new
          issue.iid          = representation.iid
          issue.project_id   = project.id
          issue.title        = representation.title
          issue.description  = format_description(representation.description, representation.author)
          issue.state        = representation.state
          issue.milestone_id = milestone_id(representation.milestone)
          issue.author_id    = author_id
          issue.created_at   = representation.created_at
          issue.updated_at   = representation.updated_at
          issue.save!(validate: false)

          issue.update(
            label_ids: label_ids(representation.labels),
            assignee_ids: assignee_ids(representation.assignees))

          fetch_comments_conditionally(issue, representation)
        end
      rescue => e
        error(:issue, representation.url, e.message)
      end
    end

    def fetch_comments_conditionally(issuable, representation)
      if representation.comments?
        comments_url = "/repos/#{repo}/issues/#{issuable.iid}/comments"
        fetch_comments(issuable, :comment, comments_url)
      end
    end

    def fetch_comments(noteable, type, url, klass = Note)
      while url
        comments = Github::Client.new(options).get(url)

        ActiveRecord::Base.no_touching do
          comments.body.each do |raw|
            begin
              representation  = Github::Representation::Comment.new(raw, options)
              author_id       = user_id(representation.author, project.creator_id)

              note            = klass.new
              note.project_id = project.id
              note.noteable   = noteable
              note.note       = format_description(representation.note, representation.author)
              note.commit_id  = representation.commit_id
              note.line_code  = representation.line_code
              note.author_id  = author_id
              note.created_at = representation.created_at
              note.updated_at = representation.updated_at
              note.save!(validate: false)
            rescue => e
              error(type, representation.url, e.message)
            end
          end
        end

        url = comments.rels[:next]
      end
    end

    def fetch_releases
      url = "/repos/#{repo}/releases"

      while url
        response = Github::Client.new(options).get(url)

        response.body.each do |raw|
          representation = Github::Representation::Release.new(raw)
          next unless representation.valid?

          release = ::Release.find_or_initialize_by(project_id: project.id, tag: representation.tag)
          next unless release.new_record?

          begin
            release.description = representation.description
            release.created_at  = representation.created_at
            release.updated_at  = representation.updated_at
            release.save!(validate: false)
          rescue => e
            error(:release, representation.url, e.message)
          end
        end

        url = response.rels[:next]
      end
    end

    def label_ids(labels)
      labels.map { |label| cached[:label_ids][label.title] }.compact
    end

    def assignee_ids(assignees)
      assignees.map { |assignee| user_id(assignee) }.compact
    end

    def milestone_id(milestone)
      return unless milestone.present?

      project.milestones.select(:id).find_by(iid: milestone.iid)&.id
    end

    def user_id(user, fallback_id = nil)
      return unless user.present?
      return cached[:user_ids][user.id] if cached[:user_ids][user.id].present?

      gitlab_user_id = user_id_by_external_uid(user.id) || user_id_by_email(user.email)

      cached[:gitlab_user_ids][user.id] = gitlab_user_id.present?
      cached[:user_ids][user.id] = gitlab_user_id || fallback_id
    end

    def user_id_by_email(email)
      return nil unless email

      ::User.find_by_any_email(email)&.id
    end

    def user_id_by_external_uid(id)
      return nil unless id

      ::User.select(:id)
            .joins(:identities)
            .merge(::Identity.where(provider: :github, extern_uid: id))
            .first&.id
    end

    def format_description(body, author)
      return body if cached[:gitlab_user_ids][author.id]

      "*Created by: #{author.username}*\n\n#{body}"
    end

    def expire_repository_cache
      repository.expire_content_cache if project.repository_exists?
    end

    def keep_track_of_errors
      return unless errors.any?

      project.update_column(:import_error, {
        message: 'The remote data could not be fully imported.',
        errors: errors
      }.to_json)
    end

    def error(type, url, message)
      errors << { type: type, url: Gitlab::UrlSanitizer.sanitize(url), error: message }
    end
  end
end
