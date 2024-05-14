# frozen_string_literal: true

class UpdateKustomizationApiVersion < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  OLD_VERSION = 'kustomize.toolkit.fluxcd.io/v1beta1'
  NEW_VERSION = 'kustomize.toolkit.fluxcd.io/v1'

  # Update flux_resource_path to replace v1beta1 with v1 for Kustomizations
  def up
    update_value = Arel.sql("REPLACE(flux_resource_path, '#{OLD_VERSION}', '#{NEW_VERSION}')")

    update_column_in_batches(:environments, :flux_resource_path, update_value) do |table, query|
      query.where(table[:flux_resource_path].matches("%#{OLD_VERSION}%"))
    end
  end

  def down
    # no-op
  end
end
