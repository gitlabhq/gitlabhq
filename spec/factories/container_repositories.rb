# frozen_string_literal: true

FactoryBot.define do
  factory :container_repository do
    sequence(:name) { |n| "test_image_#{n}" }
    project

    transient do
      tags { [] }
    end

    trait :root do
      name { '' }
    end

    trait :status_delete_scheduled do
      status { :delete_scheduled }
    end

    trait :status_delete_failed do
      status { :delete_failed }
    end

    trait :status_delete_ongoing do
      status { :delete_ongoing }
    end

    trait :cleanup_scheduled do
      expiration_policy_cleanup_status { :cleanup_scheduled }
    end

    trait :cleanup_unfinished do
      expiration_policy_cleanup_status { :cleanup_unfinished }
    end

    trait :cleanup_ongoing do
      expiration_policy_cleanup_status { :cleanup_ongoing }
    end

    trait :default do
      migration_state { 'default' }
    end

    trait :pre_importing do
      migration_state { 'pre_importing' }
      migration_pre_import_started_at { Time.zone.now }
    end

    trait :pre_import_done do
      migration_state { 'pre_import_done' }
      migration_pre_import_started_at { Time.zone.now }
      migration_pre_import_done_at { Time.zone.now }
    end

    trait :importing do
      migration_state { 'importing' }
      migration_pre_import_started_at { Time.zone.now }
      migration_pre_import_done_at { Time.zone.now }
      migration_import_started_at { Time.zone.now }
    end

    trait :import_done do
      migration_state { 'import_done' }
      migration_pre_import_started_at { Time.zone.now }
      migration_pre_import_done_at { Time.zone.now }
      migration_import_started_at { Time.zone.now }
      migration_import_done_at { Time.zone.now }
    end

    trait :import_aborted do
      migration_state { 'import_aborted' }
      migration_pre_import_started_at { Time.zone.now }
      migration_pre_import_done_at { Time.zone.now }
      migration_import_started_at { Time.zone.now }
      migration_aborted_at { Time.zone.now }
      migration_aborted_in_state { 'importing' }
      migration_retries_count { 1 }
    end

    trait :import_skipped do
      migration_state { 'import_skipped' }
      migration_skipped_at { Time.zone.now }
      migration_skipped_reason { :too_many_tags }
    end

    after(:build) do |repository, evaluator|
      next if evaluator.tags.to_a.none?

      tags = evaluator.tags
      # convert Array into Hash
      tags = tags.product(['sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15']).to_h unless tags.is_a?(Hash)
      stub_method(repository.client, :repository_tags) do |*args|
        {
          'name' => repository.path,
          'tags' => tags.keys
        }
      end

      tags.each_pair do |tag, digest|
        allow(repository.client)
          .to receive(:repository_tag_digest)
          .with(repository.path, tag)
          .and_return(digest)
      end
    end
  end
end
