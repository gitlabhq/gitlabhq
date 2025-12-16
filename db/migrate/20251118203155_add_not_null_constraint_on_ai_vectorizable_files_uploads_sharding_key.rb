# frozen_string_literal: true

class AddNotNullConstraintOnAiVectorizableFilesUploadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint(:ai_vectorizable_file_uploads, :project_id)
  end

  def down
    remove_not_null_constraint(:ai_vectorizable_file_uploads, :project_id)
  end
end
