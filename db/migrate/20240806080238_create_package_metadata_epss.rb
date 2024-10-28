# frozen_string_literal: true

class CreatePackageMetadataEpss < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    create_table :pm_epss do |t| # rubocop:disable Migration/EnsureFactoryForTable -- table is dropped in a later migration (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168288)
      t.float :score, null: false
      t.timestamps_with_timezone null: false
      t.text :cve, limit: 24, null: false, index: { unique: true }
    end
  end
end
