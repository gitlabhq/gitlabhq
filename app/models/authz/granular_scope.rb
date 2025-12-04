# frozen_string_literal: true

module Authz
  class GranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false

    # When namespace is nil, the scope grants access to user or instance standalone resources
    # When namespace is a Namespaces::UserNamespace, the scope grants access to all personal projects
    # When namespace is a Namespaces::ProjectNamespace, the scope grants access to a single project
    # When namespace is a Group, the scope grants access to a (sub)group and its descendants
    belongs_to :namespace

    validates :permissions, json_schema: { filename: 'granular_scope_permissions', size_limit: 64.kilobytes }
    validate :organization_match, if: -> { namespace.present? }

    scope :with_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }

    enum :access, {
      personal_projects: 0,
      all_memberships: 1,
      selected_memberships: 2,
      user: 3,
      instance: 4
    }

    ignore_column :all_membership_namespaces, remove_with: '18.8', remove_after: '2026-01-15'

    def self.permitted_for_boundary?(boundary, permissions)
      required_permissions = Array(permissions).map(&:to_sym)
      token_permissions = token_permissions(boundary)
      (required_permissions - token_permissions).empty?
    end

    def self.token_permissions(boundary)
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- limited permissions, and not used with IN clause
      namespace_ids = boundary.namespace&.self_and_ancestor_ids
      where.not(access: :all_memberships)
        .where(namespace_id: namespace_ids)
        .or(where(access: :all_memberships))
        .pluck(Arel.sql('DISTINCT jsonb_array_elements_text(permissions)'))
        .flat_map { |p| ::Authz::PermissionGroups::Assignable.get(p)&.permissions }
        .compact.map(&:to_sym)
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    end

    private

    def organization_match
      return if namespace.organization_id == organization_id

      errors.add(:namespace, "organization must match the token scope's organization")
    end
  end
end
