# frozen_string_literal: true

FactoryBot.define do
  factory :resource_weight_event do
    issue { create(:issue) }
    user { issue&.author || create(:user) }
  end
end
