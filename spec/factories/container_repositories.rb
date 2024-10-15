# frozen_string_literal: true

FactoryBot.define do
  factory :container_repository do
    sequence(:name) { |n| "test_image_#{n}" }
    project
    next_delete_attempt_at { nil }

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
