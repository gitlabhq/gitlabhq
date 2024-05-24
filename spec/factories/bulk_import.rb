# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import, class: 'BulkImport' do
    user
    source_type { :gitlab }
    source_version { BulkImport.min_gl_version_for_project_migration.to_s }
    source_enterprise { false }

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

    trait :timeout do
      status { 3 }
    end

    trait :with_configuration do
      configuration { association(:bulk_import_configuration, bulk_import: instance) }
    end
  end
end
