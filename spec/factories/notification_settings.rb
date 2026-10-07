# frozen_string_literal: true

FactoryBot.define do
  factory :notification_setting do
    source { @overrides[:project] || association(:project) }
    user
    level { 3 }
  end
end
