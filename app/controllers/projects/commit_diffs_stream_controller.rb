# frozen_string_literal: true

module Projects
  class CommitDiffsStreamController < Projects::CommitController
    include StreamDiffs

    private

    def resource
      commit
    end

    def options
      opts = diff_options
      opts[:offset_index] = params.permit(:offset)[:offset].to_i
      opts[:ignore_whitespace_change] = true if params.permit(:format)[:format] == 'diff'
      opts[:use_extra_viewer_as_main] = false
      opts
    end
  end
end
