# Loops through old importer projects that kept a token/password in the import URL
# and encrypts the credentials into a separate field in project#import_data
# #down method not supported
class RemoveWrongImportUrlFromProjects < ActiveRecord::Migration

  class FakeProjectImportData
    extend AttrEncrypted
    attr_accessor :credentials
    attr_encrypted :credentials, key: Gitlab::Application.secrets.db_key_base, marshal: true, encode: true, :mode => :per_attribute_iv_and_salt
  end

  def up
    byebug
    projects_with_wrong_import_url do |project|
      import_url = Gitlab::ImportUrl.new(project["import_url"])

      ActiveRecord::Base.transaction do
        execute("UPDATE projects SET import_url = #{quote(import_url.sanitized_url)} WHERE id = #{project['id']}")
        fake_import_data = FakeProjectImportData.new
        fake_import_data.credentials = import_url.credentials
        project_import_data = project_import_data(project['id'])
        if project_import_data
          execute(update_import_data_sql(project_import_data['id'], fake_import_data))
        else
          execute(insert_import_data_sql(project['id'], fake_import_data))
        end
      end
    end
  end

  def insert_import_data_sql(project_id, fake_import_data)
    %( INSERT into project_import_data (encrypted_credentials, project_id, encrypted_credentials_iv, encrypted_credentials_salt) VALUES ( #{quote(fake_import_data.encrypted_credentials)}, '#{project_id}', #{quote(fake_import_data.encrypted_credentials_iv)}, #{quote(fake_import_data.encrypted_credentials_salt)}))
  end

  def update_import_data_sql(id, fake_import_data)
    %( UPDATE project_import_data SET encrypted_credentials = #{quote(fake_import_data.encrypted_credentials)}, encrypted_credentials_iv = #{quote(fake_import_data.encrypted_credentials_iv)}, encrypted_credentials_salt = #{quote(fake_import_data.encrypted_credentials_salt)} WHERE id = '#{id}')
  end

  def projects_with_wrong_import_url
    # TODO Check live with #operations for possible false positives. Also, consider regex? But may have issues MySQL/PSQL
    select_all("SELECT p.id, p.import_url FROM projects p WHERE p.import_url IS NOT NULL AND (p.import_url LIKE '%//%:%@%' OR p.import_url LIKE 'https___#{"_"*40}@github.com%')")
  end

  def project_import_data(project_id)
    select_one("SELECT id FROM project_import_data WHERE project_id = '#{project_id}'")
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
