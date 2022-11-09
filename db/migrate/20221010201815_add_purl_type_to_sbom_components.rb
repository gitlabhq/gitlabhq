# frozen_string_literal: true

class AddPurlTypeToSbomComponents < Gitlab::Database::Migration[2.0]
  def change
    add_column :sbom_components, :purl_type, :smallint
  end
end
