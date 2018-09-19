# frozen_string_literal: true

class UserPreferenceEntity < Grape::Entity
  expose :issue_notes_filter
  expose :merge_request_notes_filter
end
