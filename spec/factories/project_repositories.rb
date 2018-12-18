# frozen_string_literal: true

FactoryBot.define do
  factory :project_repository do
    project

    after(:build) do |project_repository, _|
      project_repository.shard_name = project_repository.project.repository_storage
      project_repository.disk_path  = project_repository.project.disk_path
    end
  end
end
