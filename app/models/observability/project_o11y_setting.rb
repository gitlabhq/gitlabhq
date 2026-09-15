# frozen_string_literal: true

module Observability
  class ProjectO11ySetting < ApplicationRecord
    belongs_to :project, optional: false, inverse_of: :observability_project_o11y_setting
    belongs_to :namespace, optional: false, inverse_of: :observability_project_o11y_settings
    belongs_to :created_by, class_name: 'User', optional: true, inverse_of: :observability_project_o11y_settings

    validates :project_id, uniqueness: true
    validate :namespace_is_not_own_ancestor
    validate :namespace_can_host_observability

    scope :active, -> { where(enabled: true) }

    private

    # Pointing at an ancestor namespace is redundant - the resolver already walks the ancestry chain.
    # Only validate on create or when namespace_id changes to avoid unnecessary queries.
    def namespace_is_not_own_ancestor
      return unless project && namespace
      return unless new_record? || namespace_id_changed?
      return unless project&.namespace&.traversal_ids&.include?(namespace_id)

      errors.add(:namespace_id, 'must not be an ancestor of the project (use ancestor walk instead)')
    end

    # Project namespaces are not addressable observability targets; only groups and user namespaces can own settings.
    def namespace_can_host_observability
      return unless namespace
      return unless namespace.is_a?(Namespaces::ProjectNamespace)

      errors.add(:namespace_id, 'cannot be a project namespace')
    end
  end
end
