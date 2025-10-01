# frozen_string_literal: true

module Gitlab
  class Blame
    include Gitlab::Utils::StrongMemoize

    IGNORE_REVS_FILE_NAME = '.git-blame-ignore-revs'

    attr_accessor :blob, :commit, :range
    attr_reader :blame

    def initialize(blob, commit, range: nil, ignore_revs: nil)
      @blob = blob
      @commit = commit
      @range = range
      @ignore_revs = ignore_revs
      @blame = Gitlab::Git::Blame.new(
        repository,
        @commit.id,
        @blob.path,
        range: range,
        ignore_revisions_blob: (default_ignore_revisions_ref if ignore_revs)
      )
    end

    def first_line
      range&.first || 1
    end

    def groups(highlight: true)
      prev_sha = nil
      groups = []
      current_group = nil

      i = first_line - 1
      blame.each do |commit, line, previous_path, span|
        commit = Commit.new(commit, project)
        commit.lazy_author # preload author

        if prev_sha != commit.sha
          groups << current_group if current_group
          current_group = { commit: commit, lines: [], previous_path: previous_path, span: span, lineno: i + 1 }
        end

        current_group[:lines] << (highlight && highlighted_lines[i] ? highlighted_lines[i].html_safe : line)

        prev_sha = commit.sha
        i += 1
      end
      groups << current_group if current_group

      groups
    end

    private

    attr_reader :ignore_revs

    def default_ignore_revisions_ref
      "refs/heads/#{project.default_branch}:#{IGNORE_REVS_FILE_NAME}"
    end
    strong_memoize_attr :default_ignore_revisions_ref

    def highlighted_lines
      @blob.load_all_data!
      @highlighted_lines ||= @blob.present.highlight.lines
    end

    def project
      commit.project
    end

    def repository
      project.repository
    end
  end
end
