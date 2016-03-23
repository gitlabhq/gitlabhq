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
    say("Encrypting and migrating project import credentials...")

    say("Projects and Github projects with a wrong URL")
    in_transaction { process_projects_with_wrong_url }

    say("Migrating bitbucket credentials...")
    in_transaction { process_bitbucket_projects }
  end

  def process_projects_with_wrong_url
    projects_with_wrong_import_url.each do |project|
      import_url = Gitlab::ImportUrl.new(project["import_url"])

      update_import_url(import_url, project)
      update_import_data(import_url, project)
    end
  end

  def process_bitbucket_projects
    bitbucket_projects_with_wrong_import_url.each do |bitbucket_data|
      data_hash = YAML::load(bitbucket_data['data']) if bitbucket_data['data']
      if defined?(data_hash) && data_hash && data_hash['bb_session']
        update_import_data_for_bitbucket(data_hash, bitbucket_data['id'])
      end
    end
  end

  def in_transaction
    say_with_time("Processing new transaction...") do
      ActiveRecord::Base.transaction do
        yield
      end
    end
  end

  def update_import_data(import_url, project)
    fake_import_data = FakeProjectImportData.new
    fake_import_data.credentials = import_url.credentials
    project_import_data = project_import_data(project['id'])
    if project_import_data
      execute(update_import_data_sql(project_import_data['id'], fake_import_data))
    else
      execute(insert_import_data_sql(project['id'], fake_import_data))
    end
  end

  def update_import_data_for_bitbucket(data_hash, import_data_id)
    fake_import_data = FakeProjectImportData.new
    fake_import_data.credentials = data_hash
    execute(update_import_data_sql(import_data_id, fake_import_data))
  end

  def update_import_url(import_url, project)
    execute("UPDATE projects SET import_url = #{quote(import_url.sanitized_url)} WHERE id = #{project['id']}")
  end

  def insert_import_data_sql(project_id, fake_import_data)
    %( INSERT into project_import_data (encrypted_credentials, project_id, encrypted_credentials_iv, encrypted_credentials_salt) VALUES ( #{quote(fake_import_data.encrypted_credentials)}, '#{project_id}', #{quote(fake_import_data.encrypted_credentials_iv)}, #{quote(fake_import_data.encrypted_credentials_salt)}))
  end

  def update_import_data_sql(id, fake_import_data, data = 'NULL')
    %( UPDATE project_import_data SET encrypted_credentials = #{quote(fake_import_data.encrypted_credentials)}, encrypted_credentials_iv = #{quote(fake_import_data.encrypted_credentials_iv)}, encrypted_credentials_salt = #{quote(fake_import_data.encrypted_credentials_salt)}, data = #{data} WHERE id = '#{id}')
  end

  #Github projects with token, and any user:password@ based URL
  def projects_with_wrong_import_url
    select_all("SELECT p.id, p.import_url FROM projects p WHERE p.import_url IS NOT NULL AND (p.import_url LIKE '%//%:%@%' OR p.import_url LIKE 'https___#{"_"*40}@github.com%')")
  end

  # All bitbucket imports
  def bitbucket_projects_with_wrong_import_url
    select_all("SELECT i.id, p.import_url, i.data FROM projects p INNER JOIN project_import_data i ON p.id = i.project_id WHERE p.import_url IS NOT NULL AND p.import_type = 'bitbucket' ")
  end

  def project_import_data(project_id)
    select_one("SELECT id FROM project_import_data WHERE project_id = '#{project_id}'")
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
