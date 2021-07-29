# frozen_string_literal: true

class AddTextLimitToIntegrationsTypeNew < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :integrations, :type_new, 255
  end

  def down
    remove_text_limit :integrations, :type_new
  end
end
