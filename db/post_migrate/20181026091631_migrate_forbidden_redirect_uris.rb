# frozen_string_literal: true

class MigrateForbiddenRedirectUris < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  FORBIDDEN_SCHEMES = %w[data:// vbscript:// javascript://]
  NEW_URI = 'http://forbidden-scheme-has-been-overwritten'

  disable_ddl_transaction!

  def up
    update_forbidden_uris(:oauth_applications)
    update_forbidden_uris(:oauth_access_grants)
  end

  def down
    # noop
  end

  private

  def update_forbidden_uris(table_name)
    update_column_in_batches(table_name, :redirect_uri, NEW_URI) do |table, query|
      where_clause = FORBIDDEN_SCHEMES.map do |scheme|
        table[:redirect_uri].matches("#{scheme}%")
      end.inject(&:or)

      query.where(where_clause)
    end
  end
end
