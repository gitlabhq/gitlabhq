# frozen_string_literal: true

module Authz
  class GranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :namespace

    validates :permissions, json_schema: { filename: 'granular_scope_permissions', size_limit: 64.kilobytes }
    validate :organization_match, if: -> { namespace.present? }

    scope :with_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }

    def boundary
      namespace.present? ? namespace.class.sti_name : 'Instance'
    end

    private

    def organization_match
      return if namespace.organization_id == organization_id

      errors.add(:namespace, "organization must match the token scope's organization")
    end
  end
end
