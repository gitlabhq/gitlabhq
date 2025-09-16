# frozen_string_literal: true

module Namespaces
  module NamespaceHelper
    private

    def message_for_namespace(namespace, messages)
      # In case `namespace` is a Presenter instance, we match on the model name instead of class name.
      case namespace.model_name.name
      when 'Group'
        messages[:group]
      when 'Project', 'Namespaces::ProjectNamespace'
        messages[:project]
      else
        raise "Unsupported namespace type: #{namespace.class.name}"
      end
    end
  end
end
