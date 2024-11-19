# frozen_string_literal: true

FactoryBot.define do
  factory :ci_trigger_request, class: 'Ci::TriggerRequest' do
    trigger factory: :ci_trigger
    project_id { pipeline&.project_id || trigger&.project_id }
  end
end
