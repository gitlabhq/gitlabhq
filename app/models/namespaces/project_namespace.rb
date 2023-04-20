# frozen_string_literal: true

module Namespaces
  class ProjectNamespace < Namespace
    # These aliases are added to make it easier to sync parent/parent_id attribute with
    # project.namespace/project.namespace_id attribute.
    #
    # TODO: we can remove these attribute aliases when we no longer need to sync these with project model,
    # see project#sync_attributes
    alias_attribute :namespace, :parent
    alias_attribute :namespace_id, :parent_id
    has_one :project, foreign_key: :project_namespace_id, inverse_of: :project_namespace

    delegate :execute_hooks, :execute_integrations, to: :project, allow_nil: true

    def self.sti_name
      'Project'
    end

    def self.polymorphic_name
      'Namespaces::ProjectNamespace'
    end
  end
end
