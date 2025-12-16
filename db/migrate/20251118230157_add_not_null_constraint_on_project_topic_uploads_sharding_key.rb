# frozen_string_literal: true

class AddNotNullConstraintOnProjectTopicUploadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint(:project_topic_uploads, :organization_id)
  end

  def down
    remove_not_null_constraint(:project_topic_uploads, :organization_id)
  end
end
