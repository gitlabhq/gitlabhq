# frozen_string_literal: true

FactoryBot.define do
  factory :project_statistics do
    project

    initialize_with do
      # statistics are automatically created when a project is created
      project&.statistics || new
    end

    transient do
      with_data { false }
      size_multiplier { 1 }
    end

    after(:build) do |project_statistics, evaluator|
      if evaluator.with_data
        project_statistics.repository_size = evaluator.size_multiplier
        project_statistics.wiki_size = evaluator.size_multiplier * 2
        project_statistics.lfs_objects_size = evaluator.size_multiplier * 3
        project_statistics.build_artifacts_size = evaluator.size_multiplier * 4
        project_statistics.packages_size = evaluator.size_multiplier * 5
      end
    end
  end
end
