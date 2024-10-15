# frozen_string_literal: true

module Gitlab
  class TreeSummary
    include ::Gitlab::Utils::StrongMemoize
    include ::MarkupHelper

    CACHE_EXPIRE_IN = 1.hour
    MAX_OFFSET = (2**31) - 1

    attr_reader :commit, :project, :path, :offset, :limit, :user, :resolved_commits

    def initialize(commit, project, user, params = {})
      @commit = commit
      @project = project
      @user = user

      @path = params.fetch(:path, nil).presence
      @offset = [params.fetch(:offset, 0).to_i, MAX_OFFSET].min
      @limit = (params.fetch(:limit, 25) || 25).to_i

      # Ensure that if multiple tree entries share the same last commit, they share
      # a ::Commit instance. This prevents us from rendering the same commit title
      # multiple times
      @resolved_commits = {}
    end

    # Creates a summary of the tree entries for a commit, within the window of
    # entries defined by the offset and limit parameters. This consists of two
    # return values:
    #
    #     - An Array of Hashes containing the following keys:
    #         - file_name:   The full path of the tree entry
    #         - commit:      The last ::Commit to touch this entry in the tree
    #         - commit_path: URI of the commit in the web interface
    #         - commit_title_html: Rendered commit title
    def summarize
      return [] if offset < 0

      commits_hsh = fetch_last_cached_commits_list
      prerender_commit_full_titles!(commits_hsh.values)

      commits_hsh.map do |path_key, commit|
        commit = cache_commit(commit)

        {
          file_name: File.basename(path_key).force_encoding(Encoding::UTF_8),
          commit: commit,
          commit_path: commit_path(commit),
          commit_title_html: markdown_field(commit, :full_title)
        }
      end
    end

    def fetch_logs
      logs = summarize

      [logs.first(limit).as_json, next_offset(logs.size)]
    end

    private

    def next_offset(entries_count)
      return if entries_count <= limit

      offset + limit
    end

    def repository
      project.repository
    end

    # Ensure the path is in "path/" format
    def ensured_path
      File.join(*[path, ""]) if path
    end

    def fetch_last_cached_commits_list
      cache_key = ['projects', project.id, 'last_commits', commit.id, ensured_path, offset, limit + 1]

      commits = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRE_IN) do
        repository
          .list_last_commits_for_tree(commit.id, ensured_path, offset: offset, limit: limit + 1, literal_pathspec: true)
          .tap { |tuple| prerender_commit_full_titles!(tuple.values) }
          .transform_values! { |commit| commit_to_hash(commit) }
      end

      commits.transform_values! { |value| Commit.from_hash(value, project) }
    end

    def cache_commit(commit)
      return unless commit.present?

      resolved_commits[commit.id] ||= commit
    end

    def commit_to_hash(commit)
      commit.to_hash.tap do |hash|
        hash[:message] = hash[:message].to_s.truncate_bytes(1.kilobyte, omission: '...')
      end
    end

    def commit_path(commit)
      Gitlab::Routing.url_helpers.project_commit_path(project, commit)
    end

    def prerender_commit_full_titles!(commits)
      # Preload commit authors as they are used in rendering
      commits.each(&:lazy_author)

      renderer = Banzai::ObjectRenderer.new(user: user, default_project: project)
      renderer.render(commits, :full_title)
    end
  end
end

Gitlab::TreeSummary.prepend_mod_with('Gitlab::TreeSummary')
