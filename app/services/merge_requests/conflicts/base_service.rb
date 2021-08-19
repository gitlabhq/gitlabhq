# frozen_string_literal: true

module MergeRequests
  module Conflicts
    class BaseService
      attr_reader :merge_request, :params

      def initialize(merge_request, params = {})
        @merge_request = merge_request
        @params = params
      end
    end
  end
end
