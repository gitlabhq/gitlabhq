# frozen_string_literal: true

class PartitionPmPackageMetadataTables < Gitlab::Database::Migration[2.1]
  PURL_TYPES = (1..8).freeze

  def up
    drop_table(:pm_package_version_licenses) # rubocop:disable Migration/DropTable
    drop_table(:pm_package_versions) # rubocop:disable Migration/DropTable
    drop_table(:pm_packages) # rubocop:disable Migration/DropTable

    create_partitions_for_pm_packages
    create_partitions_for_pm_package_versions
    create_partitions_for_pm_package_version_licenses
  end

  def down
    drop_table(:pm_package_version_licenses, force: :cascade) # rubocop:disable Migration/DropTable
    drop_table(:pm_package_versions, force: :cascade) # rubocop:disable Migration/DropTable
    drop_table(:pm_packages, force: :cascade) # rubocop:disable Migration/DropTable

    create_table :pm_packages do |t|
      t.integer :purl_type, limit: 2, null: false
      t.text :name, null: false, limit: 255
      t.index [:purl_type, :name], name: 'i_pm_packages_purl_type_and_name', unique: true
    end

    create_table :pm_package_versions do |t|
      t.references :pm_package,
        index: false,
        foreign_key: {
          to_table: :pm_packages,
          column: :pm_package_id,
          name: 'fk_rails_cf94c3e601',
          on_delete: :cascade
        }
      t.text :version, null: false, limit: 255
      t.index [:pm_package_id, :version], name: 'i_pm_package_versions_on_package_id_and_version', unique: true
      t.index :pm_package_id, name: 'index_pm_package_versions_on_pm_package_id'
    end

    create_table :pm_package_version_licenses, primary_key: [:pm_package_version_id, :pm_license_id] do |t|
      t.references :pm_package_version,
        index: false,
        null: false,
        foreign_key: {
          to_table: :pm_package_versions,
          column: :pm_package_version_id,
          name: 'fk_rails_30ddb7f837',
          on_delete: :cascade
        }
      t.references :pm_license,
        index: false,
        null: false,
        foreign_key: { name: 'fk_rails_7520ea026d', on_delete: :cascade }
      t.index :pm_license_id, name: 'index_pm_package_version_licenses_on_pm_license_id'
      t.index :pm_package_version_id, name: 'index_pm_package_version_licenses_on_pm_package_version_id'
    end
  end

  private

  def create_partitions_for_pm_packages
    execute(<<~SQL)
      CREATE TABLE pm_packages (
        id BIGSERIAL NOT NULL,
        purl_type SMALLINT NOT NULL,
        name TEXT NOT NULL,
        CONSTRAINT check_9df27a82fe CHECK ((char_length(name) <= 255)),
        PRIMARY KEY (id, purl_type)
      ) PARTITION BY LIST (purl_type);
    SQL

    execute(<<~SQL)
      CREATE UNIQUE INDEX i_pm_packages_for_inserts ON pm_packages USING btree(purl_type, name);
    SQL

    PURL_TYPES.each do |i|
      execute(<<~SQL)
        CREATE TABLE gitlab_partitions_static.pm_packages_#{i}
        PARTITION OF pm_packages
        FOR VALUES IN (#{i})
      SQL
    end
  end

  def create_partitions_for_pm_package_versions
    execute(<<~SQL)
      CREATE TABLE pm_package_versions (
        id BIGSERIAL NOT NULL,
        pm_package_id BIGINT NOT NULL,
        purl_type SMALLINT NOT NULL,
        version text NOT NULL,
        CONSTRAINT check_7ed2cc733f CHECK ((char_length(version) <= 255)),
        PRIMARY KEY (id, purl_type),
        CONSTRAINT fkey_fb6234c446 FOREIGN KEY (pm_package_id, purl_type) REFERENCES pm_packages(id, purl_type) ON DELETE CASCADE
      ) PARTITION BY LIST (purl_type);
    SQL

    execute(<<~SQL)
      CREATE UNIQUE INDEX i_pm_package_versions_for_inserts ON pm_package_versions USING btree (pm_package_id, version, purl_type);
    SQL

    PURL_TYPES.each do |i|
      execute(<<~SQL)
        CREATE TABLE gitlab_partitions_static.pm_package_versions_#{i}
        PARTITION OF pm_package_versions
        FOR VALUES IN (#{i})
      SQL
    end
  end

  def create_partitions_for_pm_package_version_licenses
    execute(<<~SQL)
      CREATE TABLE pm_package_version_licenses (
        pm_package_version_id bigint NOT NULL,
        pm_license_id bigint NOT NULL,
        purl_type smallint NOT NULL,
        PRIMARY KEY (pm_package_version_id, pm_license_id, purl_type),
        CONSTRAINT pm_package_versions_fkey FOREIGN KEY (pm_package_version_id, purl_type) REFERENCES pm_package_versions (id, purl_type) ON DELETE CASCADE,
        CONSTRAINT pm_package_licenses_fkey FOREIGN KEY (pm_license_id) REFERENCES pm_licenses (id) ON DELETE CASCADE
      ) PARTITION BY LIST (purl_type);
    SQL

    execute(<<~SQL)
      CREATE INDEX i_pm_package_version_licenses_for_inserts ON pm_package_version_licenses USING btree (purl_type, pm_package_version_id, pm_license_id);
      CREATE INDEX i_pm_package_version_licenses_for_selects_on_licenses ON pm_package_version_licenses USING btree (pm_license_id);
    SQL

    PURL_TYPES.each do |i|
      execute(<<~SQL)
        CREATE TABLE gitlab_partitions_static.pm_package_version_licenses_#{i}
        PARTITION OF pm_package_version_licenses
        FOR VALUES IN (#{i})
      SQL
    end
  end
end
