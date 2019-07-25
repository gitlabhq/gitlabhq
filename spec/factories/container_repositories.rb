# frozen_string_literal: true

FactoryBot.define do
  factory :container_repository do
    name 'test_image'
    project

    transient do
      tags []
    end

    trait :root do
      name ''
    end

    after(:build) do |repository, evaluator|
      next if evaluator.tags.to_a.none?

      allow(repository.client)
        .to receive(:repository_tags)
        .and_return({
          'name' => repository.path,
          'tags' => evaluator.tags
        })

      evaluator.tags.each do |tag|
        allow(repository.client)
          .to receive(:repository_tag_digest)
          .with(repository.path, tag)
          .and_return('sha256:4c8e63ca4cb663ce6c688cb06f1c3' \
                      '72b088dac5b6d7ad7d49cd620d85cf72a15')
      end
    end
  end
end
