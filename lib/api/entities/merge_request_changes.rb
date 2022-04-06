# frozen_string_literal: true

module API
  module Entities
    class MergeRequestChanges < MergeRequest
      expose :diffs, as: :changes, using: Entities::Diff do |compare, _|
        Array(diff_collection(compare))
      end

      expose :overflow?, as: :overflow

      private

      def overflow?
        expose_raw_diffs? ? false : diff_collection(object).overflow?
      end

      def diff_collection(compare)
        @diffs ||= if expose_raw_diffs?
                     compare.raw_diffs(limits: false)
                   else
                     compare.diffs.diffs
                   end
      end

      def expose_raw_diffs?
        options[:access_raw_diffs]
      end
    end
  end
end
