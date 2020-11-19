# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import, class: 'BulkImport' do
    user
    source_type { :gitlab }

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
  end
end
