# frozen_string_literal: true

class UserPreferenceEntity < Grape::Entity
  expose :issue_notes_filter
  expose :merge_request_notes_filter

  expose :notes_filters do |user_preference|
    UserPreference.notes_filters
  end
end
