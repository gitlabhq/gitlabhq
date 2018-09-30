# frozen_string_literal: true

class UserPreference < ActiveRecord::Base
  # We could use enums, but Rails 4 doesn't support multiple
  # enum options with same name for multiple fields, also it creates
  # extra methods that aren't really needed here.
  NOTES_FILTERS = { all_notes: 0, only_comments: 1 }.freeze

  belongs_to :user

  validates :issue_notes_filter, :merge_request_notes_filter, inclusion: { in: NOTES_FILTERS.values }, presence: true

  def set_notes_filter(filter_id, issuable)
    save! unless persisted?

    # No need to update the column if the value is already set.
    if filter_id && filter_id != notes_filter_for(issuable)
      filter_name = notes_filter_field_for(issuable)
      update_column(filter_name, filter_id)
      expire_polling_etag_cache(issuable)
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

  # We need to invalidate the cache for polling notes otherwise it will
  # ignore the filter.
  # The ideal would be to invalidate the cache for each user.
  def expire_polling_etag_cache(issuable)
    issuable.expire_note_etag_cache
  end
end
