# frozen_string_literal: true

class UserPreference < ActiveRecord::Base
  # We could use enums, but Rails 4 doesn't support multiple
  # enum options with same name for multiple fields, also it creates
  # extra methods that aren't really needed here.
  NOTES_FILTERS = { all_notes: 0, only_comments: 1 }.freeze

  belongs_to :user

  validates :issue_notes_filter, :merge_request_notes_filter, inclusion: { in: NOTES_FILTERS.values }, presence: true

  def set_notes_filter(filter_id, issuable)
    # No need to update the column if the value is already set.
    if filter_id && filter_id.to_i != notes_filter_for(issuable)
      field = notes_filter_field_for(issuable)
      self[field] = filter_id

      save if attribute_changed?(field)
    end

    notes_filter_for(issuable)
  end

  # Returns the current discussion filter for a given issuable type.
  def notes_filter_for(issuable)
    self[notes_filter_field_for(issuable)]
  end

  private

  def notes_filter_field_for(issuable)
    issuable_klass = issuable.model_name.param_key
    "#{issuable_klass}_notes_filter"
  end
end
