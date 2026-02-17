# frozen_string_literal: true

class AddAuthTokenToVirtualRegistriesPackagesNpmUpstreams < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :virtual_registries_packages_npm_upstreams, :auth_token, :jsonb, if_not_exists: true
  end
end
