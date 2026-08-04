# frozen_string_literal: true

module MergeRequests
  class SavedView < ApplicationRecord
    self.table_name = 'merge_request_saved_views'

    MAX_NAME_LENGTH = 255
    MAX_VIEWS_PER_USER = 5
    FILTERS_SIZE_LIMIT = 8.kilobytes

    belongs_to :user, optional: false, inverse_of: :merge_request_saved_views

    validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
    validates :name, uniqueness: { scope: :user_id }
    validates :filters,
      json_schema: { filename: 'merge_request_saved_view_filters', size_limit: FILTERS_SIZE_LIMIT }

    validate :validate_views_limit, on: :create

    scope :for_user, ->(user) { where(user: user) }

    # Overridden in EE
    def self.views_limit
      MAX_VIEWS_PER_USER
    end

    private

    def validate_views_limit
      return if user_id.blank?
      return if self.class.for_user(user_id).count < self.class.views_limit

      errors.add(
        :base,
        format(
          s_('MergeRequestSavedViews|You can create a maximum of %{limit} saved views.'),
          limit: self.class.views_limit
        )
      )
    end
  end
end

MergeRequests::SavedView.prepend_mod
