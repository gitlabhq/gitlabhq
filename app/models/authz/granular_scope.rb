# frozen_string_literal: true

module Authz
  class GranularScope < ApplicationRecord
    COPYABLE_ATTRIBUTES = %w[organization_id namespace_id permissions access].freeze

    belongs_to :organization, class_name: 'Organizations::Organization', optional: false

    # When namespace is nil, the scope grants access to user or instance standalone resources
    # When namespace is a Namespaces::UserNamespace, the scope grants access to all personal projects
    # When namespace is a Namespaces::ProjectNamespace, the scope grants access to a single project
    # When namespace is a Group, the scope grants access to a (sub)group and its descendants
    belongs_to :namespace

    validates :permissions, json_schema: { filename: 'granular_scope_permissions', size_limit: 64.kilobytes }
    validate :organization_match, if: -> { namespace.present? }

    scope :with_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }
    scope :for_standalone, ->(access) do
      where(namespace_id: nil, access: access).where.not(access: Access::ALL_MEMBERSHIPS)
    end
    scope :for_namespaces, ->(namespaces) do
      where(namespace_id: namespaces, access: [Access::PERSONAL_PROJECTS, Access::SELECTED_MEMBERSHIPS])
        .or(where(namespace_id: nil, access: Access::ALL_MEMBERSHIPS))
    end

    module Access
      PERSONAL_PROJECTS = :personal_projects
      ALL_MEMBERSHIPS = :all_memberships
      SELECTED_MEMBERSHIPS = :selected_memberships
      USER = :user
      INSTANCE = :instance

      LEVELS = {
        PERSONAL_PROJECTS => 0,
        ALL_MEMBERSHIPS => 1,
        SELECTED_MEMBERSHIPS => 2,
        USER => 3,
        INSTANCE => 4
      }.freeze
    end

    enum :access, Access::LEVELS

    def self.permitted_for_boundary?(boundary, permissions)
      required_permissions = Array(permissions).map(&:to_sym)
      token_permissions = token_permissions(boundary)
      (required_permissions - token_permissions).empty?
    end

    def self.token_permissions(boundary)
      scope = case boundary.access
              when Access::USER, Access::INSTANCE
                for_standalone(boundary.access)
              when Access::SELECTED_MEMBERSHIPS
                for_namespaces(boundary.namespace.self_and_ancestor_ids)
              end

      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- limited permissions, and not used with IN clause
      scope
        .pluck(Arel.sql('DISTINCT jsonb_array_elements_text(permissions)'))
        .flat_map { |p| ::Authz::PermissionGroups::Assignable.get(p)&.permissions }
        .compact.map(&:to_sym)
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    end

    def build_copy
      self.class.build(attributes.slice(*COPYABLE_ATTRIBUTES))
    end

    private

    def organization_match
      return if namespace.organization_id == organization_id

      errors.add(:namespace, "organization must match the token scope's organization")
    end
  end
end
