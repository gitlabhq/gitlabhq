# frozen_string_literal: true

FactoryBot.define do
  factory :import_source_user, class: 'Import::SourceUser' do
    namespace
    source_user_identifier { SecureRandom.uuid }
    source_hostname { 'https://github.com' }
    source_name { generate(:name) }
    source_username { generate(:username) }
    import_type { 'github' }
    placeholder_user factory: [:user, :placeholder]

    trait :with_reassign_to_user do
      reassign_to_user factory: :user
    end

    trait :with_reassigned_by_user do
      reassigned_by_user factory: :user
    end

    trait :pending_reassignment do
      status { 0 }
    end

    trait :awaiting_approval do
      with_reassign_to_user
      reassignment_token { SecureRandom.hex }
      status { 1 }
    end

    trait :reassignment_in_progress do
      with_reassign_to_user
      status { 2 }
    end

    trait :rejected do
      status { 3 }
    end

    trait :completed do
      with_reassign_to_user
      status { 5 }
    end

    trait :keep_as_placeholder do
      status { 6 }
    end
  end
end
