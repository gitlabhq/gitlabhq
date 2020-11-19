# frozen_string_literal: true

module Gitlab
  module Graphql
    module ConnectionRedaction
      class RedactionState
        attr_reader :redactor
        attr_reader :redacted_nodes

        def redactor=(redactor)
          @redactor = redactor
          @redacted_nodes = nil
        end

        def redacted(&block)
          @redacted_nodes ||= redactor.present? ? redactor.redact(yield) : yield
        end
      end

      delegate :redactor=, to: :redaction_state

      def nodes
        redaction_state.redacted { super.to_a }
      end

      private

      def redaction_state
        @redaction_state ||= RedactionState.new
      end
    end
  end
end
