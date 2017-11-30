class GeoProjectRegistryEntity < Grape::Entity
  expose :project_id
  expose :last_repository_synced_at
  expose :last_repository_successful_sync_at
  expose :last_wiki_synced_at
  expose :last_wiki_successful_sync_at
  expose :repository_retry_count
  expose :wiki_retry_count
  expose :last_repository_sync_failure
  expose :last_wiki_sync_failure
end
