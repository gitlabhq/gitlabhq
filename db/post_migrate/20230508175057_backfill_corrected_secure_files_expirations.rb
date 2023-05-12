# frozen_string_literal: true

class BackfillCorrectedSecureFilesExpirations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 1000

  def up
    each_batch_range('ci_secure_files', of: BATCH_SIZE) do |min, max|
      sql = <<-SQL
        SELECT id
        FROM ci_secure_files
        WHERE name ILIKE any (array['%.cer', '%.p12'])
        AND ci_secure_files.id BETWEEN #{min} AND #{max}
      SQL

      rows = execute(sql)

      rows.each do |row|
        ::Ci::ParseSecureFileMetadataWorker.perform_async(row["id"])
      end
    end
  end

  def down; end
end
