# frozen_string_literal: true

class CreatePackagesConanPackageRevisions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  UNIQ_IND_PACKAGE_REFERENCE_REVISION = 'uniq_idx_on_packages_conan_package_revisions_revision'

  def change
    create_table :packages_conan_package_revisions do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :package_id, null: false
      t.bigint :project_id, null: false
      t.bigint :package_reference_id, null: false
      t.timestamps_with_timezone null: false
      t.binary :revision, null: false, limit: 20 # It is either an MD5 hash (16 bytes) or a SHA-1 hash (20 bytes)

      t.index :project_id
      t.index :package_reference_id
      t.index [:package_id, :package_reference_id, :revision], unique: true, name: UNIQ_IND_PACKAGE_REFERENCE_REVISION
    end
  end
end
