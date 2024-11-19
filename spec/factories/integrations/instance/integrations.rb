# frozen_string_literal: true

FactoryBot.define do
  factory :instance_integration, class: 'Integrations::Instance::Integration' do
    type { 'Integrations::Instance::Integration' }
  end
end
