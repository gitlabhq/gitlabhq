class GeoNodeStatusEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper

  expose :id

  expose :healthy?, as: :healthy
  expose :health do |node|
    node.healthy? ? 'Healthy' : node.health
  end

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

  expose :last_event_id
  expose :last_event_timestamp
  expose :cursor_last_event_id
  expose :cursor_last_event_timestamp
end
