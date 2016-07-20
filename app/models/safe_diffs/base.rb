module SafeDiffs
  class Base
    attr_reader :project, :diff_options, :diff_view, :diff_refs

    delegate :count, :real_size, to: :diff_files

    def initialize(diffs, project:, diff_options:, diff_refs: nil)
      @diffs = diffs
      @project = project
      @diff_options = diff_options
      @diff_refs = diff_refs
    end

    def diff_files
      @diff_files ||= begin
        diffs = @diffs.decorate! do |diff|
          Gitlab::Diff::File.new(diff, diff_refs: @diff_refs, repository: @project.repository)
        end

        highlight!(diffs)
        diffs
      end
    end

    private

    def highlight!(diff_files)
      if cacheable?
        cache_highlight!(diff_files)
      else
        diff_files.each { |diff_file| highlight_diff_file!(diff_file) }
      end
    end

    def cacheable?
      false
    end

    def cache_highlight!
      raise NotImplementedError
    end

    def highlight_diff_file_from_cache!(diff_file, cache_diff_lines)
      diff_file.diff_lines = cache_diff_lines.map do |line|
        Gitlab::Diff::Line.init_from_hash(line)
      end
    end

    def highlight_diff_file!(diff_file)
      diff_file.diff_lines = Gitlab::Diff::Highlight.new(diff_file, repository: diff_file.repository).highlight
      diff_file.highlighted_diff_lines = diff_file.diff_lines # To be used on parallel diff
      diff_file
    end
  end
end
