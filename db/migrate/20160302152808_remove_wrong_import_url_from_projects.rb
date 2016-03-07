class RemoveWrongImportUrlFromProjects < ActiveRecord::Migration

  class ImportUrlSanitizer
    def initialize(url)
      @url = URI.parse(url)
    end

    def sanitized_url
      @sanitized_url ||= safe_url
    end

    def credentials
      @credentials ||= { user: @url.user, password: @url.password }
    end

    private

    def safe_url
      safe_url = @url.dup
      safe_url.password = nil
      safe_url.user = nil
      safe_url
    end

  end

  class FakeProjectImportData
    extend AttrEncrypted
    attr_accessor :credentials
    attr_encrypted :credentials, key: Gitlab::Application.secrets.db_key_base, marshal: true, encode: true
  end

  def up
    projects_with_wrong_import_url.each do |project|
      sanitizer = ImportUrlSanitizer.new(project["import_url"])

      ActiveRecord::Base.transaction do
        execute("UPDATE projects SET import_url = '#{sanitizer.sanitized_url}' WHERE id = #{project['id']}")
        fake_import_data = FakeProjectImportData.new
        fake_import_data.credentials = sanitizer.credentials
        execute("UPDATE project_import_data SET encrypted_credentials = '#{fake_import_data.encrypted_credentials}' WHERE project_id = #{project['id']}")
      end
    end
  end

  def projects_with_wrong_import_url
    # TODO Check live with #operations for possible false positives. Also, consider regex? But may have issues MySQL/PSQL
    select_all("SELECT p.id, p.import_url from projects p WHERE p.import_url LIKE '%//%:%@%' or p.import_url like '#{"_"*40}@github.com%'")
  end
end
