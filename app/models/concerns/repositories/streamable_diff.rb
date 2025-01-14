# frozen_string_literal: true

module Repositories
  module StreamableDiff
    extend ActiveSupport::Concern

    def diffs_for_streaming(diff_options = {}, &)
      if block_given?
        offset = diff_options[:offset_index].to_i || 0
        repository.diffs_by_changed_paths(diff_refs, offset, &)
      else
        diffs(diff_options)
      end
    end
  end
end
