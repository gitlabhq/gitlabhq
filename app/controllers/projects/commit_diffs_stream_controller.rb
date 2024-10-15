# frozen_string_literal: true

module Projects
  class CommitDiffsStreamController < Projects::CommitController
    include StreamDiffs

    private

    def resource
      commit
    end

    def streaming_diff_options
      opts = super

      opts[:ignore_whitespace_change] = true if params.permit(:format)[:format] == 'diff'
      opts[:use_extra_viewer_as_main] = false

      opts
    end
  end
end
