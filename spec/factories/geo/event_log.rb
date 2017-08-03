FactoryGirl.define do
  factory :geo_event_log, class: Geo::EventLog do
    repository_updated_event factory: :geo_repository_update_event
  end

  factory :geo_repository_update_event, class: Geo::RepositoryUpdatedEvent do
    source 0
    branches_affected 0
    tags_affected 0
    project
  end
end
