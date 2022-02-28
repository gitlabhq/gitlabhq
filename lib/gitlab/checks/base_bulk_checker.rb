# frozen_string_literal: true

module Gitlab
  module Checks
    class BaseBulkChecker < BaseChecker
      attr_reader :changes_access

      delegate(*ChangesAccess::ATTRIBUTES, to: :changes_access)

      def initialize(changes_access)
        @changes_access = changes_access
      end

      def validate!
        raise NotImplementedError
      end
    end
  end
end
