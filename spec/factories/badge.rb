FactoryBot.define do
  trait :base_badge do
    link_url { generate(:url) }
    image_url { generate(:url) }
  end

  factory :project_badge, traits: [:base_badge], class: ProjectBadge do
    project
  end

  factory :group_badge, aliases: [:badge], traits: [:base_badge], class: GroupBadge do
    group
  end
end
