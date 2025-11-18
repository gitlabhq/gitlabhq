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
      blame.each.with_index(first_line).with_object([]) do |((commit, line, previous_path, span), line_number), groups|
        if groups.empty? || groups.last[:commit].sha != commit.sha
          groups << {
            commit: wrapped_commit(commit, project),
            lines: [],
            previous_path: previous_path,
            span: span,
            lineno: line_number
          }
        end

        groups.last[:lines] << current_line(highlight, line, line_number)
      end
    ensure
      clear_memoization(:wrapped_commit)
    end

    private

    def current_line(highlight, line, line_number)
      return line unless highlight && (highlighted_line = highlighted_lines[line_number - 1]) # rubocop:disable Lint/AssignmentInCondition -- not assigning would make this less performant with very large files as we would iterate through the highlighted_lines array twice

      highlighted_line.html_safe
    end

    def wrapped_commit(commit, project)
      strong_memoize_with(:wrapped_commit, commit.sha) do
        Commit.new(commit, project).tap(&:lazy_author)
      end
    end

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
