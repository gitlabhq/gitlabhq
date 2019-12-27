# frozen_string_literal: true

class AddWildcardAndDomainTypeToPagesDomains < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  PROJECT_TYPE = 2

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default :pages_domains, :wildcard, :boolean, default: false
    add_column_with_default :pages_domains, :domain_type, :integer, limit: 2, default: PROJECT_TYPE
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_column :pages_domains, :wildcard
    remove_column :pages_domains, :domain_type
  end
end
