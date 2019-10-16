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

    after(:build) do |repository, evaluator|
      next if evaluator.tags.to_a.none?

      tags = evaluator.tags
      # convert Array into Hash
      tags = tags.product(['sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15']).to_h unless tags.is_a?(Hash)

      allow(repository.client)
        .to receive(:repository_tags)
        .and_return({
          'name' => repository.path,
          'tags' => tags.keys
        })

      tags.each_pair do |tag, digest|
        allow(repository.client)
          .to receive(:repository_tag_digest)
          .with(repository.path, tag)
          .and_return(digest)
      end
    end
  end
end
