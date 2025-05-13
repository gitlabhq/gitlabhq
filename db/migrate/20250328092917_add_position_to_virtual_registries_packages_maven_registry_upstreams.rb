# frozen_string_literal: true

class AddPositionToVirtualRegistriesPackagesMavenRegistryUpstreams < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams
  STARTING_POSITION = 1

  def change
    add_column TABLE_NAME,
      :position,
      :smallint,
      null: false,
      default: STARTING_POSITION
  end
end
