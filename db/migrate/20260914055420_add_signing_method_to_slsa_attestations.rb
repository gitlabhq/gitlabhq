# frozen_string_literal: true

class AddSigningMethodToSlsaAttestations < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :slsa_attestations, :signing_method, :smallint, null: false, default: 0
  end
end
