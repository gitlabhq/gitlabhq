# frozen_string_literal: true

module Gitlab
  class TreeSummary
    include ::Gitlab::Utils::StrongMemoize
    include ::MarkupHelper

    CACHE_EXPIRE_IN = 1.hour
    MAX_OFFSET = 2**31

    attr_reader :commit, :project, :path, :offset, :limit, :user

    attr_reader :resolved_commits
    private :resolved_commits

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
    #         - type:        One of :blob, :tree, or :submodule
    #         - commit:      The last ::Commit to touch this entry in the tree
    #         - commit_path: URI of the commit in the web interface
    #     - An Array of the unique ::Commit objects in the first value
    def summarize
      summary = contents
        .map { |content| build_entry(content) }
        .tap { |summary| fill_last_commits!(summary) }

      [summary, commits]
    end

    def fetch_logs
      cache_key = ['projects', project.id, 'logs', commit.id, path, offset]
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRE_IN) do
        logs, _ = summarize

        new_offset = next_offset if more?

        [logs.as_json, new_offset]
      end
    end

    # Does the tree contain more entries after the given offset + limit?
    def more?
      all_contents[next_offset].present?
    end

    # The offset of the next batch of tree entries. If more? returns false, this
    # batch will be empty
    def next_offset
      [all_contents.size + 1, offset + limit].min
    end

    private

    def contents
      all_contents[offset, limit]
    end

    def commits
      resolved_commits.values
    end

    def repository
      project.repository
    end

    def entry_path(entry)
      File.join(*[path, entry[:file_name]].compact).force_encoding(Encoding::ASCII_8BIT)
    end

    def build_entry(entry)
      { file_name: entry.name, type: entry.type }
    end

    def fill_last_commits!(entries)
      # Ensure the path is in "path/" format
      ensured_path =
        if path
          File.join(*[path, ""])
        end

      commits_hsh = repository.list_last_commits_for_tree(commit.id, ensured_path, offset: offset, limit: limit)
      prerender_commit_full_titles!(commits_hsh.values)

      entries.each do |entry|
        path_key = entry_path(entry)
        commit = cache_commit(commits_hsh[path_key])

        if commit
          entry[:commit] = commit
          entry[:commit_path] = commit_path(commit)
          entry[:commit_title_html] = markdown_field(commit, :full_title)
        end
      end
    end

    def cache_commit(commit)
      return unless commit.present?

      resolved_commits[commit.id] ||= commit
    end

    def commit_path(commit)
      Gitlab::Routing.url_helpers.project_commit_path(project, commit)
    end

    def all_contents
      strong_memoize(:all_contents) do
        [
          *tree.trees,
          *tree.blobs,
          *tree.submodules
        ]
      end
    end

    def tree
      strong_memoize(:tree) { repository.tree(commit.id, path) }
    end

    def prerender_commit_full_titles!(commits)
      # Preload commit authors as they are used in rendering
      commits.each(&:lazy_author)

      renderer = Banzai::ObjectRenderer.new(user: user, default_project: project)
      renderer.render(commits, :full_title)
    end
  end
end

Gitlab::TreeSummary.prepend_if_ee('::EE::Gitlab::TreeSummary')
