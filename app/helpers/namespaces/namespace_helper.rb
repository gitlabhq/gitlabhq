# frozen_string_literal: true

module Namespaces
  module NamespaceHelper
    private

    def message_for_namespace(namespace, messages)
      owner_entity_name = namespace.try(:owner_entity_name)
      raise "Unsupported namespace type: #{namespace.class.name}" unless %i[group project].include?(owner_entity_name)

      messages[owner_entity_name]
    end
  end
end
