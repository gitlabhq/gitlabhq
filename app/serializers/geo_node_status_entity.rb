class GeoNodeStatusEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper

  expose :id

  expose :healthy?, as: :healthy
  expose :health do |node|
    node.healthy? ? 'No Health Problems Detected' : node.health
  end

  expose :lfs_objects_total, as: :lfs_objects_count
  expose :lfs_objects_synced, as: :lfs_objects_synced_count
  expose :lfs_objects_synced_in_percentage do |node|
    number_to_percentage(node.lfs_objects_synced_in_percentage, precision: 2)
  end

  expose :repositories_count
  expose :repositories_failed_count
  expose :repositories_synced_count
  expose :repositories_synced_in_percentage do |node|
    number_to_percentage(node.repositories_synced_in_percentage, precision: 2)
  end
end
