# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_event, class: '::AntiAbuse::Event' do
    user
    category { :spam }
    source { :spamcheck }

    after(:build) do |event, evaluator|
      event.organization_id ||= evaluator.user.organization_id
    end

    trait(:with_abuse_report) do
      abuse_report
    end
  end
end
