# frozen_string_literal: true

class AddStatusToVirtualRegistriesPackagesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :virtual_registries_packages_maven_cached_responses, :status, :smallint, default: 0, null: false
  end
end
