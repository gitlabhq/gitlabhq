# frozen_string_literal: true

module Authz
  class GranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
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
      find_by_namespace_id(boundary.namespace)&.permissions&.map(&:to_sym) || []
    end

    private

    def organization_match
      return if namespace.organization_id == organization_id

      errors.add(:namespace, "organization must match the token scope's organization")
    end
  end
end
