# frozen_string_literal: true

FactoryBot.define do
  factory :instance_integration, class: 'Integrations::InstanceIntegration' do
    type { 'Integrations::InstanceIntegration' }
  end
end
