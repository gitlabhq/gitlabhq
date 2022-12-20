# frozen_string_literal: true

FactoryBot.define do
  factory :resource_milestone_event do
    issue { merge_request.nil? ? association(:issue) : nil }
    merge_request { nil }
    milestone
    action { :add }
    state { :opened }
    user { issue&.author || merge_request&.author || association(:user) }
  end
end
