# frozen_string_literal: true

class ChangeMaxArtifactsContentIncludeSizeToBigint < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    change_column :application_settings, :max_artifacts_content_include_size, :bigint,
      default: 5242880, null: false
  end

  def down
    change_column :application_settings, :max_artifacts_content_include_size, :integer,
      default: 5242880, null: false
  end
end
