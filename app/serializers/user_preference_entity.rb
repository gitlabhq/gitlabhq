# frozen_string_literal: true

class UserPreferenceEntity < Grape::Entity
  expose :issue_discussion_filter
  expose :merge_request_discussion_filter
end
