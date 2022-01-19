# frozen_string_literal: true

FactoryBot.define do
  factory :wiki do
    transient do
      container { association(:project) }
      user { container.first_owner || association(:user) }
    end

    initialize_with { Wiki.for_container(container, user) }
    skip_create

    factory :project_wiki do
      transient do
        project { association(:project) }
      end

      container { project }
    end

    trait :empty_repo do
      after(:create, &:create_wiki_repository)
    end
  end
end
