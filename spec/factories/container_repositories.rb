FactoryGirl.define do
  factory :container_repository do
    name 'test_container_image'
    project

    transient do
      tags []
    end

    after(:build) do |repository, evaluator|
      if evaluator.tags.any?
        allow(repository.client)
          .to receive(:repository_tags)
          .and_return({
            name: repository.path,
            tags: evaluator.tags
          })
      end
    end
  end
end
