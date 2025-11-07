# frozen_string_literal: true

module Authz
  class GranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false

    # When namespace is nil, the scope represents permissions for standalone resources: for a user or for the instance
    # When namespace is a Namespaces::UserNamespace, the scope represents permissions for all personal projects
    # When namespace is a Namespaces::ProjectNamespace, the scope represents permissions for a single project
    # When namespace is a Group, the scope represents permissions for a (sub)group and it's descendants
    belongs_to :namespace

    validates :permissions, json_schema: { filename: 'granular_scope_permissions', size_limit: 64.kilobytes }
    validate :organization_match, if: -> { namespace.present? }

    scope :with_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }

    def self.permitted_for_boundary?(boundary, permissions)
      required_permissions = Array(permissions).map(&:to_sym)
      token_permissions = token_permissions(boundary)
      (required_permissions - token_permissions).empty?
    end

    def self.token_permissions(boundary)
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- limited permissions, and not used with IN clause
      namespace_ids = boundary.namespace&.self_and_ancestor_ids
      where(all_membership_namespaces: false)
        .where(namespace_id: namespace_ids)
        .or(where(all_membership_namespaces: true))
        .pluck(Arel.sql('DISTINCT jsonb_array_elements_text(permissions)'))
        .map(&:to_sym)
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    end

    private

    def organization_match
      return if namespace.organization_id == organization_id

      errors.add(:namespace, "organization must match the token scope's organization")
    end
  end
end
