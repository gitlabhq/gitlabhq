# frozen_string_literal: true

module MergeRequests
  module Conflicts
    class BaseService
      attr_reader :merge_request

      def initialize(merge_request)
        @merge_request = merge_request
      end
    end
  end
end
