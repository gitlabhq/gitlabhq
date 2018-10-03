# frozen_string_literal: true

class UserPreferenceEntity < Grape::Entity
  expose :issue_notes_filter
  expose :merge_request_notes_filter

  expose :notes_filters do |user_preference|
    {
      _('Notes|Show all activity') => UserPreference::NOTES_FILTERS[:all_notes],
      _('Notes|Show comments only') => UserPreference::NOTES_FILTERS[:only_comments]
    }
  end
end
