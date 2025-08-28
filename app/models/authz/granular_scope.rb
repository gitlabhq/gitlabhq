# frozen_string_literal: true

module Authz
  class GranularScope < ApplicationRecord
    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :namespace

    validates :permissions, json_schema: { filename: 'granular_scope_permissions', size_limit: 64.kilobytes }

    def boundary
      namespace.present? ? namespace.class.sti_name : 'Instance'
    end
  end
end
