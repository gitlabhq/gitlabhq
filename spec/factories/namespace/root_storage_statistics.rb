# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_root_storage_statistics, class: 'Namespace::RootStorageStatistics' do
    namespace
  end
end
