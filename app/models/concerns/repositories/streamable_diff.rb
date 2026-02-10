# frozen_string_literal: true

module Repositories
  module StreamableDiff
    extend ActiveSupport::Concern

    def diffs_for_streaming(diff_options = {})
      diffs(diff_options)
    end

    def diffs_for_streaming_by_changed_paths(diff_options = {}, &)
      offset = diff_options[:offset_index].to_i || 0
      repository.diffs_by_changed_paths(diff_refs, offset, &)
    end
  end
end
