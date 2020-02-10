# frozen_string_literal: true

class AddElasticsearchIndexedFieldLengthLimitToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :application_settings, :elasticsearch_indexed_field_length_limit, :integer, null: false, default: 0

    if Gitlab.com?
      execute 'UPDATE application_settings SET elasticsearch_indexed_field_length_limit = 20000'
    end
  end

  def down
    remove_column :application_settings, :elasticsearch_indexed_field_length_limit
  end
end
