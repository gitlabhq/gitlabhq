# frozen_string_literal: true

module Organizations
  class OrganizationSetting < ApplicationRecord
    belongs_to :organization

    validates :settings, json_schema: { filename: "organization_settings" }

    jsonb_accessor :settings,
      restricted_visibility_levels: [:integer, { array: true, default: [] }],
      default_group_visibility: :integer

    validates_each :restricted_visibility_levels do |record, attr, value|
      value&.each do |level|
        unless Gitlab::VisibilityLevel.options.value?(level)
          record.errors.add(attr, format(_("'%{level}' is not a valid visibility level"), level: level))
        end
      end
    end

    validates :default_group_visibility,
      exclusion: { in: :restricted_visibility_levels, message: "cannot be set to a restricted visibility level" },
      inclusion: { in: Gitlab::VisibilityLevel.values, allow_nil: true },
      if: :should_prevent_visibility_restriction?

    def self.for(organization_id)
      return unless organization_id

      Organizations::OrganizationSetting.find_or_initialize_by(organization_id: organization_id)
    end

    private

    # This method is based off the ApplicationSetting method with the same name.
    # This method is an optimization to perform visibility validation only when some fields have changed.
    def should_prevent_visibility_restriction?
      default_group_visibility_changed? || restricted_visibility_levels_changed?
    end
  end
end
