# frozen_string_literal: true

module Gitlab
  module Fp
    class UnmatchedResultError < RuntimeError
      # @param [Gitlab::Fp::Result] result
      # @return [void]
      def initialize(result:)
        msg = "Failed to pattern match #{result.ok? ? "'ok'" : "'err'"} Result " \
          "containing message of type: #{(result.ok? ? result.unwrap : result.unwrap_err).class.name}"

        super(msg)
      end
    end
  end
end
