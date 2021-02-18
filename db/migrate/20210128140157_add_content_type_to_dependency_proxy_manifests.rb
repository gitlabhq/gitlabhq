# frozen_string_literal: true

class AddContentTypeToDependencyProxyManifests < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210128140232_add_text_limit_to_dependency_proxy_manifests_content_type.rb
  def change
    add_column :dependency_proxy_manifests, :content_type, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
