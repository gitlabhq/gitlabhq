# frozen_string_literal: true

FactoryBot.define do
  factory :ci_trigger_without_token, class: 'Ci::Trigger' do
    owner

    factory :ci_trigger do
      sequence(:token) { |n| "#{Ci::Trigger.prefix_for_trigger_token}token#{n}" }
    end
  end
end
