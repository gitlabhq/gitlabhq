# frozen_string_literal: true

class UserPreference < ActiveRecord::Base
  # We could use enums, but Rails 4 doesn't support multiple
  # enum options with same name for multiple fields, also it creates
  # extra methods that aren't really needed here.
  NOTES_FILTERS = { all_notes: 0, only_comments: 1 }.freeze

  belongs_to :user, inverse_of: :user_preference

  validates :user, presence: true
  validates :issue_notes_filter, :merge_request_notes_filter, inclusion: { in: NOTES_FILTERS.values }, presence: true

  def set_notes_filter(filter_id, issuable)
    # No need to update the column if the value is already set.
    if filter_id && filter_id != notes_filter_for(issuable)
      filter_name = notes_filter_field_for(issuable)
      update_column(filter_name, filter_id)
    end

    notes_filter_for(issuable)
  end

  # Returns the current discussion filter for a given issuable type.
  def notes_filter_for(issuable)
    case issuable
    when Issue
      issue_notes_filter
    when MergeRequest
      merge_request_notes_filter
    end
  end

  private

  def notes_filter_field_for(issuable)
    issuable_klass = issuable.model_name.param_key
    "#{issuable_klass}_notes_filter"
  end
end
