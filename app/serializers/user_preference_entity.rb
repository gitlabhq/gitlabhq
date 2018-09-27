# frozen_string_literal: true

class UserPreferenceEntity < Grape::Entity
  include RequestAwareEntity

  expose :issue_notes_filter
  expose :merge_request_notes_filter

  expose :user_preferences_path do |user|
    profile_preferences_path
  end
end
