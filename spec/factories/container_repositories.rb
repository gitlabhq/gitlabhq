FactoryGirl.define do
  factory :container_repository do
    name "test_container_image"
    project

    transient do
      tags ['tag']
    end

    after(:build) do |image, evaluator|
      # if evaluator.tags.to_a.any?
      #   allow(Gitlab.config.registry).to receive(:enabled).and_return(true)
      #   allow(Auth::ContainerRegistryAuthenticationService)
      #     .to receive(:full_access_token).and_return('token')
      #   allow(image.client).to receive(:repository_tags).and_return({
      #     name: image.name_with_namespace,
      #     tags: evaluator.tags
      #   })
      # end
    end
  end
end
