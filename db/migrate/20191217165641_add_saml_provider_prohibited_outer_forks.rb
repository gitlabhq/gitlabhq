# frozen_string_literal: true

class AddSamlProviderProhibitedOuterForks < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :saml_providers, :prohibited_outer_forks, :boolean, default: false, allow_null: true # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :saml_providers, :prohibited_outer_forks
  end
end
