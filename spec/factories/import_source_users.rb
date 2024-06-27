# frozen_string_literal: true

FactoryBot.define do
  factory :import_source_user, class: 'Import::SourceUser' do
    namespace
    source_user_identifier { SecureRandom.uuid }
    source_hostname { 'github.com' }
    import_type { 'github' }

    trait :with_placeholder_user do
      placeholder_user factory: [:user, :placeholder]
    end

    trait :with_reassign_to_user do
      reassign_to_user factory: :user
    end

    trait :with_reassigned_by_user do
      reassigned_by_user factory: :user
    end

    trait :awaiting_approval do
      status { 1 }
    end

    trait :completed do
      status { 5 }
    end
  end
end
