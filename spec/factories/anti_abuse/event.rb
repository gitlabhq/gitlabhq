# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_event, class: 'AntiAbuse::Event' do
    user
    category { :spam }
    source { :spamcheck }

    trait(:with_abuse_report) do
      abuse_report
    end
  end
end
