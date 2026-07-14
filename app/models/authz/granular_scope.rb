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

    def expanded_permissions
      Array(permissions)
        .flat_map { |p| ::Authz::PermissionGroups::Assignable.get(p)&.permissions }
        .compact.map(&:to_sym)
    end

    def applicable_to_boundary?(boundary)
      case boundary.access
      when Access::USER, Access::INSTANCE
        standalone_access?(boundary.access)
      when Access::SELECTED_MEMBERSHIPS
        namespace_access?(boundary) || all_memberships_access?
      else
        false
      end
    end

    def build_copy
      self.class.build(attributes.slice(*COPYABLE_ATTRIBUTES))
    end

    private

    def standalone_access?(access_level)
      namespace_id.nil? && access.to_sym == access_level
    end

    def namespace_access?(boundary)
      [Access::SELECTED_MEMBERSHIPS, Access::PERSONAL_PROJECTS].include?(access.to_sym) &&
        boundary.namespace.self_and_ancestor_ids.include?(namespace_id)
    end

    def all_memberships_access?
      namespace_id.nil? && access.to_sym == Access::ALL_MEMBERSHIPS
    end

    def organization_match
      return if namespace.organization_id == organization_id

      errors.add(:namespace, "organization must match the token scope's organization")
    end
  end
end
