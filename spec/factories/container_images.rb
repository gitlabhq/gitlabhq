FactoryGirl.define do
  factory :container_image do
    name "test_container_image"
    project

    transient do
      tags ['tag']
      stubbed true
    end

    after(:build) do |image, evaluator|
      if evaluator.stubbed
        allow(Gitlab.config.registry).to receive(:enabled).and_return(true)
        allow(image.client).to receive(:repository_tags).and_return({
          name: image.name_with_namespace,
          tags: evaluator.tags
        })
      end
    end
  end
end
