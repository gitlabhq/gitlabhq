# frozen_string_literal: true

FactoryBot.define do
  factory :import_source_user, class: 'Import::SourceUser' do
    namespace
    source_user_identifier { SecureRandom.uuid }
    source_hostname { 'github.com' }
    source_name { generate(:name) }
    source_username { generate(:username) }
    import_type { 'github' }

    trait :with_placeholder_user do
      placeholder_user factory: [:user, :placeholder]
    end

    trait :with_reassign_to_user do
      with_placeholder_user
      reassign_to_user factory: :user
    end

    trait :with_reassigned_by_user do
      reassigned_by_user factory: :user
    end

    trait :pending_assignment do
      status { 0 }
    end

    trait :awaiting_approval do
      status { 1 }
    end

    trait :completed do
      status { 5 }
    end

    trait :keep_as_placeholder do
      status { 6 }
    end
  end
end
