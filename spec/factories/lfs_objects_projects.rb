# frozen_string_literal: true

FactoryBot.define do
  factory :lfs_objects_project do
    lfs_object
    project
    repository_type { :project }

    trait :project_repository_type do
      repository_type { :project }
    end

    trait :wiki_repository_type do
      repository_type { :wiki }
    end

    trait :design_repository_type do
      repository_type { :design }
    end

    trait :null_repository_type do
      repository_type { nil }
    end
  end
end
