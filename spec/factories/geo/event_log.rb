FactoryGirl.define do
  factory :geo_event_log, class: Geo::EventLog do
    trait :updated_event do
      repository_updated_event factory: :geo_repository_updated_event
    end

    trait :deleted_event do
      repository_deleted_event factory: :geo_repository_deleted_event
    end
  end

  factory :geo_repository_updated_event, class: Geo::RepositoryUpdatedEvent do
    source 0
    branches_affected 0
    tags_affected 0
    project
  end

  factory :geo_repository_deleted_event, class: Geo::RepositoryDeletedEvent do
    project

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    deleted_path { project.path_with_namespace }
    deleted_project_name { project.name }
  end

  factory :geo_repository_renamed_event, class: Geo::RepositoryRenamedEvent do
    project

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    old_path_with_namespace { project.full_path }
    new_path_with_namespace { project.full_path }
    old_wiki_path_with_namespace { project.wiki.path_with_namespace }
    new_wiki_path_with_namespace { project.wiki.path_with_namespace }
    old_path { project.path }
    new_path { project.path }
  end

  factory :geo_repositories_changed_event, class: Geo::RepositoriesChangedEvent do
    geo_node
  end
end
