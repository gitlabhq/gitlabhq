class UserPreference < ActiveRecord::Base
  # We could use enums, but Rails 4 doesn't support multiple
  # enum options with same name for multiple fields, also it creates
  # extra methods that aren't really needed here.
  DISCUSSION_FILTERS = { all_activity: 0, comments: 1 }.freeze

  has_one :user, inverse_of: :user_preference

  validates :issue_discussion_filter, :merge_request_discussion_filter,
    inclusion: { in: DISCUSSION_FILTERS.values }, presence: true

  def set_discussion_filter(filter_id, issuable)
    # No need to update the column if the value is already set.
    if filter_id != discussion_filter(issuable)
      filter_name = discussion_filter_for_issuable(issuable)
      update_column(filter_name, filter_id)
    end

    discussion_filter(issuable)
  end

  # Returns the current discussion filter for a given issuable type.
  def discussion_filter(issuable)
    filter_name = discussion_filter_for_issuable(issuable)

    public_send(filter_name) # rubocop:disable GitlabSecurity/PublicSend
  end

  private

  def discussion_filter_for_issuable(issuable)
    issuable_klass = issuable.model_name.param_key
    "#{issuable_klass}_discussion_filter"
  end
end
