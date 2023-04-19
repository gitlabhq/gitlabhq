# frozen_string_literal: true

class ResyncScanResultPoliciesForNamespaces < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 50

  class Group < MigrationRecord
    self.inheritance_column = :_type_disabled
    self.table_name = 'namespaces'

    def self.as_ids
      select(Arel.sql('namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)]').as('id'))
    end

    def self_and_descendant_ids
      self.class.where("traversal_ids @> ('{?}')", id).as_ids
    end
  end

  class Project < MigrationRecord
    self.table_name = 'projects'
  end

  class OrchestrationPolicyConfiguration < MigrationRecord
    include EachBatch
    self.table_name = 'security_orchestration_policy_configurations'
  end

  def up
    return unless Gitlab.ee?
    return unless process_scan_result_policy_worker

    OrchestrationPolicyConfiguration
      .where.not(namespace_id: nil)
      .each_batch(column: :namespace_id, of: BATCH_SIZE) do |policy_configurations|
        policy_configurations.each do |policy_configuration|
          for_each_project(policy_configuration) do |project|
            process_scan_result_policy_worker.perform_async(project.id, policy_configuration.id)
          end
        end
      end
  end

  def down
    # no-op
  end

  private

  def for_each_project(policy_configuration)
    scope = Project.order(:id)
    array_scope = Group.find(policy_configuration.namespace_id).self_and_descendant_ids
    array_mapping_scope = ->(id_expression) do
      Project.where(Project.arel_table[:namespace_id].eq(id_expression)).select(:id)
    end

    query_builder = Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
      scope: scope,
      array_scope: array_scope,
      array_mapping_scope: array_mapping_scope
    )

    query_builder.execute.limit(BATCH_SIZE).each do |project|
      yield(project) if block_given?
    end
  end

  def process_scan_result_policy_worker
    unless defined?(@process_scan_result_policy_worker)
      @process_scan_result_policy_worker = 'Security::ProcessScanResultPolicyWorker'.safe_constantize
    end

    @process_scan_result_policy_worker
  end
end
