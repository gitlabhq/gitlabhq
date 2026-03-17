# frozen_string_literal: true

FactoryBot.define do
  factory :offline_export, class: 'Import::Offline::Export' do
    user
    organization

    source_hostname { 'https://offline-environment-gitlab.example.com' }

    trait :created do
      status { 0 }
    end

    trait :started do
      status { 1 }
    end

    trait :finished do
      status { 2 }
    end

    trait :failed do
      status { -1 }
    end

    trait :with_configuration do
      configuration { association(:import_offline_configuration, offline_export: instance) }
    end
  end
end
