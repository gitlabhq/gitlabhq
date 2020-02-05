# frozen_string_literal: true

module API
  module Entities
    class MergeRequestChanges < MergeRequest
      expose :diffs, as: :changes, using: Entities::Diff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end
  end
end
