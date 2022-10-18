# frozen_string_literal: true

class UserPreference < ApplicationRecord
  include IgnorableColumns

  # We could use enums, but Rails 4 doesn't support multiple
  # enum options with same name for multiple fields, also it creates
  # extra methods that aren't really needed here.
  NOTES_FILTERS = { all_notes: 0, only_comments: 1, only_activity: 2 }.freeze

  belongs_to :user

  scope :with_user, -> { joins(:user) }
  scope :gitpod_enabled, -> { where(gitpod_enabled: true) }

  validates :issue_notes_filter, :merge_request_notes_filter, inclusion: { in: NOTES_FILTERS.values }, presence: true
  validates :tab_width, numericality: {
    only_integer: true,
    greater_than_or_equal_to: Gitlab::TabWidth::MIN,
    less_than_or_equal_to: Gitlab::TabWidth::MAX
  }
  validates :diffs_deletion_color, :diffs_addition_color,
            format: { with: ColorsHelper::HEX_COLOR_PATTERN },
            allow_blank: true
  validates :use_legacy_web_ide, allow_nil: false, inclusion: { in: [true, false] }

  ignore_columns :experience_level, remove_with: '14.10', remove_after: '2021-03-22'

  default_value_for :tab_width, value: Gitlab::TabWidth::DEFAULT, allows_nil: false
  default_value_for :time_display_relative, value: true, allows_nil: false
  default_value_for :time_format_in_24h, value: false, allows_nil: false
  default_value_for :render_whitespace_in_code, value: false, allows_nil: false

  class << self
    def notes_filters
      {
        s_('Notes|Show all activity') => NOTES_FILTERS[:all_notes],
        s_('Notes|Show comments only') => NOTES_FILTERS[:only_comments],
        s_('Notes|Show history only') => NOTES_FILTERS[:only_activity]
      }
    end
  end

  def set_notes_filter(filter_id, issuable)
    # No need to update the column if the value is already set.
    if filter_id && NOTES_FILTERS.value?(filter_id)
      field = notes_filter_field_for(issuable)
      self[field] = filter_id

      save if attribute_changed?(field)
    end

    notes_filter_for(issuable)
  end

  # Returns the current discussion filter for a given issuable
  # or issuable type.
  def notes_filter_for(resource)
    self[notes_filter_field_for(resource)]
  end

  private

  def notes_filter_field_for(resource)
    field_key =
      if resource.is_a?(Issuable)
        resource.model_name.param_key
      else
        resource
      end

    "#{field_key}_notes_filter"
  end
end

UserPreference.prepend_mod_with('UserPreference')
