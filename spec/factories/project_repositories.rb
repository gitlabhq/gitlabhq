# frozen_string_literal: true

FactoryBot.define do
  factory :project_repository do
    project { association(:project_with_repo) }
    shard_name { project.repository_storage || 'shard_name' }
    disk_path { |n| "@hashed/unique_#{n}_#{SecureRandom.hex(8)}" }

    # Override to prevent double creation
    initialize_with { project.project_repository || new(attributes) }
  end
end
