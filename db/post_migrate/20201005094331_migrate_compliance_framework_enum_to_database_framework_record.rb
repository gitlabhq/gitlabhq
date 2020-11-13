# frozen_string_literal: true

class MigrateComplianceFrameworkEnumToDatabaseFrameworkRecord < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class TmpComplianceFramework < ActiveRecord::Base
    self.table_name = 'compliance_management_frameworks'
  end

  class TmpProjectSettings < ActiveRecord::Base
    # Maps data between ComplianceManagement::ComplianceFramework::FRAMEWORKS(enum) and new ComplianceManagement::Framework model
    ENUM_FRAMEWORK_MAPPING = {
      1 => {
        name: 'GDPR',
        description: 'General Data Protection Regulation',
        color: '#1aaa55'
      }.freeze,
      2 => {
        name: 'HIPAA',
        description: 'Health Insurance Portability and Accountability Act',
        color: '#1f75cb'
      }.freeze,
      3 => {
        name: 'PCI-DSS',
        description: 'Payment Card Industry-Data Security Standard',
        color: '#6666c4'
      }.freeze,
      4 => {
        name: 'SOC 2',
        description: 'Service Organization Control 2',
        color: '#dd2b0e'
      }.freeze,
      5 => {
        name: 'SOX',
        description: 'Sarbanes-Oxley',
        color: '#fc9403'
      }.freeze
    }.freeze

    self.table_name = 'project_compliance_framework_settings'

    include EachBatch

    def raw_compliance_framework
      # Because we have an `enum` definition in ComplianceManagement::ComplianceFramework::ProjectSettings, this is very unlikely to fail.
      ENUM_FRAMEWORK_MAPPING.fetch(framework).merge(namespace_id: root_namespace_id)
    end
  end

  def up
    TmpComplianceFramework.reset_column_information
    TmpProjectSettings.reset_column_information

    # This is our standard recursive namespace query, we use it to determine the root_namespace_id in the same query.
    lateral_join = <<~SQL
      INNER JOIN LATERAL (
        WITH RECURSIVE "base_and_ancestors" AS (
          (
            SELECT "ns".* FROM "namespaces" as ns WHERE "ns"."id" = projects.namespace_id
          ) UNION
          (
             SELECT "ns".* FROM "namespaces" as ns, "base_and_ancestors" WHERE "ns"."id" = "base_and_ancestors"."parent_id"
          )
        ) SELECT "namespaces".* FROM "base_and_ancestors" AS "namespaces" WHERE parent_id IS NULL LIMIT 1) AS root_namespaces ON TRUE
    SQL

    TmpProjectSettings.each_batch(of: 100) do |query|
      project_settings_with_root_group = query
        .select(:project_id, :framework, 'root_namespaces.id as root_namespace_id')
        .from("(SELECT * FROM project_compliance_framework_settings) as project_compliance_framework_settings") # this is needed for the LATERAL JOIN
        .joins("INNER JOIN projects on projects.id = project_compliance_framework_settings.project_id")
        .joins(lateral_join)
        .to_a

      ActiveRecord::Base.transaction do
        raw_frameworks = project_settings_with_root_group.map(&:raw_compliance_framework)
        TmpComplianceFramework.insert_all(raw_frameworks.uniq) # Create compliance frameworks per group

        unique_namespace_ids = project_settings_with_root_group.map(&:root_namespace_id).uniq

        framework_records = TmpComplianceFramework.select(:id, :namespace_id, :name).where(namespace_id: unique_namespace_ids)

        project_settings_with_root_group.each do |project_setting|
          framework = framework_records.find do |record|
            # name is unique within a group
            record.name == project_setting.raw_compliance_framework[:name] && record[:namespace_id] == project_setting.raw_compliance_framework[:namespace_id]
          end

          project_setting.update_column(:framework_id, framework.id)
        end
      end
    end
  end

  def down
    # data migration, no-op
  end
end
