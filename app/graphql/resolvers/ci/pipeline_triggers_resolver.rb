# frozen_string_literal: true

module Resolvers
  module Ci
    class PipelineTriggersResolver < BaseResolver
      include LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :admin_build
      type Types::Ci::PipelineTriggerType.connection_type, null: false

      def resolve_with_lookahead
        triggers = ::Ci::TriggersFinder.new(current_user, object).execute
        apply_lookahead(triggers)
      end

      private

      def unconditional_includes
        [:trigger_requests]
      end
    end
  end
end
