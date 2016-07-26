module Gitlab
  module Diff
    module FileCollection

      class Base
        attr_reader :project, :diff_options, :diff_view, :diff_refs

        delegate :count, :size, :real_size, to: :diff_files

        def initialize(diffs, project:, diff_options:, diff_refs: nil)
          @diffs        = diffs
          @project      = project
          @diff_options = diff_options
          @diff_refs    = diff_refs
        end

        def diff_files
          @diffs.decorate! { |diff| decorate_diff!(diff) }
        end

        private

        def decorate_diff!(diff)
          return diff if diff.is_a?(Gitlab::Diff::File)
          Gitlab::Diff::File.new(diff, diff_refs: @diff_refs, repository: @project.repository)
        end
      end
    end
  end
end
