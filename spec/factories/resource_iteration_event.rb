# frozen_string_literal: true

FactoryBot.define do
  factory :resource_iteration_event do
    issue { merge_request.nil? ? create(:issue) : nil }
    merge_request { nil }
    iteration
    action { :add }
    user { issue&.author || merge_request&.author || create(:user) }
  end
end
