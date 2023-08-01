# frozen_string_literal: true

module Discussions
  class CaptureDiffNotePositionsService
    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute
      return unless merge_request.has_complete_diff_refs?

      discussions, paths = build_discussions

      service = Discussions::CaptureDiffNotePositionService.new(merge_request, paths)

      discussions.each do |discussion|
        service.execute(discussion)
      end
    end

    private

    attr_reader :merge_request

    def build_discussions
      active_diff_discussions = merge_request.notes.new_diff_notes.discussions.select do |discussion|
        discussion.active?(merge_request.diff_refs)
      end
      paths = active_diff_discussions.flat_map { |n| n.diff_file&.paths }

      [active_diff_discussions, paths]
    end
  end
end
