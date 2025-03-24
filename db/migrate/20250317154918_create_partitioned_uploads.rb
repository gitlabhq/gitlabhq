# frozen_string_literal: true

class CreatePartitionedUploads < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.11'

  disable_ddl_transaction!

  TABLE_NAME = 'uploads'
  PARTITIONED_TABLE_PK = %w[id model_type]

  def up
    partition_table_by_list(
      TABLE_NAME, 'model_type', primary_key: PARTITIONED_TABLE_PK,
      partition_mappings: partition_mappings,
      partition_name_format: '%{partition_name}_uploads',
      create_partitioned_table_fn: ->(name) { create_partitioned_table(name) },
      sync_trigger: false
    )
  end

  def down
    drop_partitioned_table_for(TABLE_NAME)
  end

  private

  # rubocop:disable Migration/Datetime -- Creating a copy of existing table
  # rubocop:disable Migration/AddLimitToTextColumns -- Creating a copy of existing table
  # rubocop:disable Migration/EnsureFactoryForTable -- Creating a copy of existing table
  def create_partitioned_table(name)
    options = 'PARTITION BY LIST (model_type)'

    # Table name should by provided by `partition_table_by_list`, but when using variable some
    # Rubocop rules fail to handle this, so we use the name that would be generated instead.
    create_table :uploads_9ba88c4165, primary_key: PARTITIONED_TABLE_PK, options: options do |t|
      t.bigint :id, null: false
      t.bigint :size, null: false
      t.bigint :model_id, null: false
      t.references :uploaded_by_user, index: false, foreign_key: { to_table: :users, on_delete: :nullify }
      t.bigint :organization_id
      t.bigint :namespace_id
      t.bigint :project_id
      t.timestamp :created_at
      t.integer :store, null: false, default: 1
      t.integer :version, default: 1
      t.text :path, null: false, limit: 511
      t.text :checksum, limit: 64
      t.text :model_type
      t.text :uploader, null: false
      t.text :mount_point
      t.text :secret

      t.index :checksum, name: "index_#{name}_on_checksum"
      t.index [:model_id, :model_type, :uploader, :created_at], name: "index_#{name}_on_model_uploader_created_at"
      t.index :store, name: "index_#{name}_on_store"
      t.index :uploaded_by_user_id, name: "index_#{name}_on_uploaded_by_user_id"
      t.index [:uploader, :path], name: "index_#{name}_on_uploader_and_path"
      t.index :organization_id, name: "index_#{name}_on_organization_id"
      t.index :namespace_id, name: "index_#{name}_on_namespace_id"
      t.index :project_id, name: "index_#{name}_on_project_id"
    end
  end
  # rubocop:enable Migration/EnsureFactoryForTable
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/Datetime

  def partition_mappings
    {
      abuse_report: "AbuseReport",
      achievement: "Achievements::Achievement",
      ai_vectorizable_file: "Ai::VectorizableFile",
      alert_management_alert_metric_image: "AlertManagement::MetricImage",
      appearance: "Appearance",
      bulk_import_export_upload: "BulkImports::ExportUpload",
      dependency_list_export: "Dependencies::DependencyListExport",
      dependency_list_export_part: "Dependencies::DependencyListExport::Part",
      design_management_action: "DesignManagement::Action",
      note: "Note",
      namespace: "Namespace",
      import_export_upload: "ImportExportUpload",
      issuable_metric_image: "IssuableMetricImage",
      organization_detail: "Organizations::OrganizationDetail",
      snippet: "Snippet",
      project: "Project",
      project_import_export_relation_export_upload: "Projects::ImportExport::RelationExportUpload",
      project_topic: "Projects::Topic",
      user: "User",
      user_permission_export_upload: "UserPermissionExportUpload",
      vulnerability_archive_export: "Vulnerabilities::ArchiveExport",
      vulnerability_export: "Vulnerabilities::Export",
      vulnerability_export_part: "Vulnerabilities::Export::Part",
      vulnerability_remediation: "Vulnerabilities::Remediation"
    }.transform_values { |value| "'#{value}'" }
  end
end
