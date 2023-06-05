# frozen_string_literal: true

module Resolvers
  module AuditEvents
    class AuditEventDefinitionsResolver < BaseResolver
      type [Types::AuditEvents::DefinitionType], null: false

      def resolve
        Gitlab::Audit::Type::Definition.definitions.values
      end
    end
  end
end
