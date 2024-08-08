# frozen_string_literal: true

class MaxArtifactsContentIncludeSize < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :application_settings, :max_artifacts_content_include_size, :integer, default: 5.megabytes, null: false
  end
end
