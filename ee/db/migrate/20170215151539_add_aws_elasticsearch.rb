class AddAwsElasticsearch < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :elasticsearch_url, :string, default: 'http://localhost:9200'
    add_column :application_settings, :elasticsearch_aws, :boolean, default: false, null: false
    add_column :application_settings, :elasticsearch_aws_region, :string, default: 'us-east-1'
    add_column :application_settings, :elasticsearch_aws_access_key, :string
    add_column :application_settings, :elasticsearch_aws_secret_access_key, :string
  end
end
