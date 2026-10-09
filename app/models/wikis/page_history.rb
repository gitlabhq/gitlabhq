# frozen_string_literal: true

module Wikis
  class PageHistory
    include Gitlab::Utils::StrongMemoize

    MAX_VERSIONS = 1_000
    CHANGED_PATH_STATUSES = %i[DIFF_STATUS_ADDED DIFF_STATUS_DELETED DIFF_STATUS_RENAMED].freeze

    def initialize(wiki_page)
      @wiki_page = wiki_page
    end

    def count
      return commits.size if commits

      path_commit_count
    end

    def versions(page: 1)
      per_page = Kaminari.config.default_per_page
      offset = ([page.to_i, 1].max - 1) * per_page

      return commits[offset, per_page] || [] if commits

      repository.commits(wiki.default_branch, path: wiki_page.path, follow: false, limit: per_page, offset: offset)
    end

    private

    attr_reader :wiki_page

    delegate :wiki, to: :wiki_page
    delegate :repository, to: :wiki

    def commits
      return if path_commit_count > MAX_VERSIONS

      collected = collect_commits
      collected if collected.size <= MAX_VERSIONS
    end
    strong_memoize_attr :commits

    def path_commit_count
      repository.count_commits(revisions: wiki.default_branch, path: wiki_page.path)
    end
    strong_memoize_attr :path_commit_count

    def collect_commits
      collected = []
      segment = [wiki.default_branch, wiki_page.path]

      while segment && collected.size <= MAX_VERSIONS
        revision, path = segment
        limit = MAX_VERSIONS + 1 - collected.size
        segment_commits = repository.commits(revision, path: path, follow: false, limit: limit).to_a
        previous_paths = previous_paths_by_commit_id(segment_commits, path)
        rename_index = segment_commits.find_index { |commit| previous_paths.key?(commit.id) }

        collected.concat(rename_index ? segment_commits.first(rename_index + 1) : segment_commits)
        segment = rename_index && previous_segment(segment_commits[rename_index], previous_paths)
      end

      collected
    end

    def previous_segment(rename_commit, previous_paths)
      ["#{rename_commit.id}^", previous_paths[rename_commit.id]]
    end

    def previous_paths_by_commit_id(commits, path)
      changed_paths = repository.find_changed_paths!(
        commits.reject(&:merge_commit?), find_renames: true, diff_filters: CHANGED_PATH_STATUSES
      )

      changed_paths.group_by(&:commit_id).filter_map do |commit_id, changes|
        previous_path = renamed_from(changes, path) || redirected_from(commit_id, changes, path)

        [commit_id, previous_path] if previous_path
      end.to_h
    end

    def renamed_from(changes, path)
      changes.find { |change| change.renamed_file? && change.path == path }&.old_path
    end

    def redirected_from(commit_id, changes, path)
      return unless changes.any? { |change| change.new_file? && change.path == path }

      deleted_paths = changes.select(&:deleted_file?).map(&:path)
      return if deleted_paths.empty?

      slug = url_path(path)
      sources = redirects_at(commit_id).filter_map { |from, to| from.to_s if to.to_s == slug }

      deleted_paths.find { |deleted_path| sources.include?(url_path(deleted_path)) }
    end

    def redirects_at(revision)
      blob = repository.blob_at(revision, Wiki::REDIRECTS_YML, limit: Wiki::REDIRECTS_YML_SIZE_LIMIT)
      return {} if blob.nil? || blob.truncated?

      redirects = YAML.safe_load(blob.data)
      redirects.is_a?(Hash) ? redirects : {}
    rescue Psych::Exception
      {}
    end

    def url_path(path)
      Pathname(path).sub_ext('').to_s
    end
  end
end
