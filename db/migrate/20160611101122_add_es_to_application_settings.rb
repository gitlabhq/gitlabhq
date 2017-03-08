class AddEsToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :elasticsearch_indexing, :boolean, default: false, null: false
    add_column :application_settings, :elasticsearch_search, :boolean, default: false, null: false
    add_column :application_settings, :elasticsearch_host, :string, default: 'localhost'
    add_column :application_settings, :elasticsearch_port, :string, default: '9200'

    es_enabled = Settings.elasticsearch['enabled']

    es_host = Settings.elasticsearch['host']
    es_host = es_host.join(',') if es_host.is_a?(Array)

    es_port = Settings.elasticsearch['port']

    execute <<-SQL.strip_heredoc
      UPDATE application_settings
      SET
        elasticsearch_indexing = #{es_enabled},
        elasticsearch_search = #{es_enabled},
        elasticsearch_host = '#{es_host}',
        elasticsearch_port = '#{es_port}'
    SQL
  end

  def down
    remove_column :application_settings, :elasticsearch_indexing
    remove_column :application_settings, :elasticsearch_search
    remove_column :application_settings, :elasticsearch_host
    remove_column :application_settings, :elasticsearch_port
  end
end
