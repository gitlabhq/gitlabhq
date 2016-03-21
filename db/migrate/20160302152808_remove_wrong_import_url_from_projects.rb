class RemoveWrongImportUrlFromProjects < ActiveRecord::Migration

  class FakeProjectImportData
    extend AttrEncrypted
    attr_accessor :credentials
    attr_encrypted :credentials, key: Gitlab::Application.secrets.db_key_base, marshal: true, encode: true
  end

  def up
    projects_with_wrong_import_url.find_in_batches do |project_batch|
      project_batch.each do |project|
        sanitizer = Gitlab::ImportUrlSanitizer.new(project["import_url"])

        ActiveRecord::Base.transaction do
          execute("UPDATE projects SET import_url = '#{quote(sanitizer.sanitized_url)}' WHERE id = #{project['id']}")
          fake_import_data = FakeProjectImportData.new
          fake_import_data.credentials = sanitizer.credentials
          execute("UPDATE project_import_data SET encrypted_credentials = '#{quote(fake_import_data.encrypted_credentials)}' WHERE project_id = #{project['id']}")
        end
      end
    end
  end

  def down

  end

  def projects_with_wrong_import_url
    # TODO Check live with #operations for possible false positives. Also, consider regex? But may have issues MySQL/PSQL
    select_all("SELECT p.id, p.import_url FROM projects p WHERE p.import_url IS NOT NULL AND (p.import_url LIKE '%//%:%@%' OR p.import_url LIKE '#{"_"*40}@github.com%')")
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
