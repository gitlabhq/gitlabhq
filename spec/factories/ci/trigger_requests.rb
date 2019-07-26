# frozen_string_literal: true

FactoryBot.define do
  factory :ci_trigger_request, class: Ci::TriggerRequest do
    trigger factory: :ci_trigger
  end
end
