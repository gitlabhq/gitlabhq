# frozen_string_literal: true

FactoryBot.define do
  factory :snippet_statistics do
    snippet factory: :project_snippet

    initialize_with do
      # statistics are automatically created when a snippet is created
      snippet&.statistics || new
    end

    transient do
      with_data { false }
      size_multiplier { 1 }
    end

    after(:build) do |snippet_statistics, evaluator|
      if evaluator.with_data
        snippet_statistics.repository_size = evaluator.size_multiplier
        snippet_statistics.commit_count = evaluator.size_multiplier * 2
        snippet_statistics.file_count = evaluator.size_multiplier * 3
      end
    end
  end
end
