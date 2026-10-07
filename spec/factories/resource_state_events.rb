# frozen_string_literal: true

FactoryBot.define do
  factory :resource_state_event do
    issue { @overrides[:work_item] || (association(:issue) if merge_request.nil?) }
    merge_request { nil }
    state { :opened }
    user { issue&.author || merge_request&.author || association(:user) }
  end
end
