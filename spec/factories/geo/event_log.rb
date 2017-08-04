FactoryGirl.define do
  factory :geo_event_log, class: Geo::EventLog do
    trait :updated_event do
      repository_updated_event factory: :geo_repository_update_event
    end

    trait :deleted_event do
      repository_deleted_event factory: :geo_repository_delete_event
    end
  end

  factory :geo_repository_update_event, class: Geo::RepositoryUpdatedEvent do
    source 0
    branches_affected 0
    tags_affected 0
    project
  end

  factory :geo_repository_delete_event, class: Geo::RepositoryDeletedEvent do
    project

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    deleted_path { project.path_with_namespace }
    deleted_project_name { project.name }
  end
end
