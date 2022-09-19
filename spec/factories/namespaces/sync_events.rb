# frozen_string_literal: true

FactoryBot.define do
  factory :sync_event, class: 'Namespaces::SyncEvent' do
    association :namespace, factory: :namespace, strategy: :build
  end
end
