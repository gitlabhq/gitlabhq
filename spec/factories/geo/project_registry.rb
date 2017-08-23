FactoryGirl.define do
  factory :geo_project_registry, class: Geo::ProjectRegistry do
    project
    last_repository_synced_at nil
    last_repository_successful_sync_at nil
    last_wiki_synced_at nil
    last_wiki_successful_sync_at nil
    resync_repository true
    resync_wiki true

    trait :dirty do
      resync_repository true
      resync_wiki true
    end

    trait :repository_dirty do
      resync_repository true
      resync_wiki false
    end

    trait :wiki_dirty do
      resync_repository false
      resync_wiki true
    end

    trait :synced do
      last_repository_synced_at { 5.days.ago }
      last_repository_successful_sync_at { 5.days.ago }
      last_wiki_synced_at { 5.days.ago }
      last_wiki_successful_sync_at { 5.days.ago }
      resync_repository false
      resync_wiki false
    end

    trait :sync_failed do
      last_repository_synced_at { 5.days.ago }
      last_repository_successful_sync_at nil
      last_wiki_synced_at { 5.days.ago }
      last_wiki_successful_sync_at nil
      resync_repository true
      resync_wiki true
    end

    trait :repository_sync_failed do
      last_repository_synced_at { 5.days.ago }
      last_repository_successful_sync_at nil
      last_wiki_synced_at { 5.days.ago }
      last_wiki_successful_sync_at  { 5.days.ago }
      resync_repository true
      resync_wiki false
    end

    trait :wiki_sync_failed do
      last_repository_synced_at { 5.days.ago }
      last_repository_successful_sync_at { 5.days.ago }
      last_wiki_synced_at { 5.days.ago }
      last_wiki_successful_sync_at nil
      resync_repository false
      resync_wiki true
    end
  end
end
