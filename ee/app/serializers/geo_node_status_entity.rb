class GeoNodeStatusEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper

  expose :geo_node_id

  expose :healthy?, as: :healthy
  expose :health do |node|
    node.healthy? ? 'Healthy' : node.health
  end
  expose :health_status
  expose :missing_oauth_application, as: :missing_oauth_application

  expose :attachments_count
  expose :attachments_synced_count
  expose :attachments_failed_count
  expose :attachments_synced_in_percentage do |node|
    number_to_percentage(node.attachments_synced_in_percentage, precision: 2)
  end

  expose :db_replication_lag_seconds

  expose :lfs_objects_count
  expose :lfs_objects_synced_count
  expose :lfs_objects_failed_count
  expose :lfs_objects_synced_in_percentage do |node|
    number_to_percentage(node.lfs_objects_synced_in_percentage, precision: 2)
  end

  expose :repositories_count
  expose :repositories_failed_count
  expose :repositories_synced_count
  expose :repositories_synced_in_percentage do |node|
    number_to_percentage(node.repositories_synced_in_percentage, precision: 2)
  end

  expose :wikis_count
  expose :wikis_failed_count
  expose :wikis_synced_count
  expose :wikis_synced_in_percentage do |node|
    number_to_percentage(node.wikis_synced_in_percentage, precision: 2)
  end

  expose :replication_slots_count
  expose :replication_slots_used_count
  expose :replication_slots_used_in_percentage do |node|
    number_to_percentage(node.replication_slots_used_in_percentage, precision: 2)
  end
  expose :replication_slots_max_retained_wal_bytes

  expose :last_event_id
  expose :last_event_timestamp
  expose :cursor_last_event_id
  expose :cursor_last_event_timestamp

  expose :last_successful_status_check_timestamp

  expose :version
  expose :revision

  expose :namespaces, using: NamespaceEntity

  # We load GeoNodeStatus data in two ways:
  #
  # 1. Directly by asking a Geo node via an API call
  # 2. Via cached state in the database
  #
  # We don't yet cached the state of the shard information in the database, so if
  # we don't have this information omit from the serialization entirely.
  expose :storage_shards, using: StorageShardEntity, if: ->(status, options) do
    status.storage_shards.present?
  end

  expose :storage_shards_match?, as: :storage_shards_match, if: -> (status, options) do
    Gitlab::Geo.primary? && status.storage_shards.present?
  end

  private

  def namespaces
    object.geo_node.namespaces
  end

  def missing_oauth_application
    object.geo_node.missing_oauth_application?
  end

  def version
    Gitlab::VERSION
  end

  def revision
    Gitlab::REVISION
  end
end
