# frozen_string_literal: true

class CreatePackagesConanJwtSigningKeys < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    create_table :packages_conan_jwt_signing_keys do |t|
      t.timestamps_with_timezone null: false
      t.jsonb :secret_key, null: false
    end
  end
end
