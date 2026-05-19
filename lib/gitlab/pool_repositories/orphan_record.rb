# frozen_string_literal: true

module Gitlab
  module PoolRepositories
    class OrphanRecord
      ORPHAN_REASONS = {
        pool_in_db_no_projects: 'Pool exists in Rails DB but no projects reference it',
        pool_no_source_project: 'Pool exists in Rails DB with no source_project_id set',
        pool_on_gitaly_missing_db: 'Pool exists on Gitaly but missing from Rails DB',
        disk_path_mismatch: 'Disk path mismatch between Rails DB and Gitaly',
        pool_in_obsolete_state: 'Pool marked as obsolete in Rails DB'
      }.freeze

      def self.from_pool(pool_repository, reasons, gitaly_relative_path = nil)
        reasons_array = Array(reasons)
        validate_reasons(reasons_array)
        reason_codes = reasons_array.map(&:to_s).join('|')
        reason_texts = reasons_array.map { |r| ORPHAN_REASONS[r] || "Unknown reason: #{r}" }.join('; ')

        {
          pool_id: pool_repository.id,
          disk_path: pool_repository.disk_path,
          relative_path: gitaly_relative_path || 'N/A',
          source_project_id: pool_repository.source_project_id,
          state: pool_repository.state,
          reason_codes: reason_codes,
          reasons: reason_texts,
          member_projects_count: pool_repository.member_projects.size,
          shard_name: pool_repository.shard_name
        }
      end

      def self.from_gitaly(pool_disk_path, storage_name)
        {
          pool_id: 'N/A',
          disk_path: pool_disk_path,
          relative_path: "#{pool_disk_path}.git",
          source_project_id: nil,
          state: 'unknown',
          reason_codes: 'pool_on_gitaly_missing_db',
          reasons: ORPHAN_REASONS[:pool_on_gitaly_missing_db],
          member_projects_count: 0,
          shard_name: storage_name
        }
      end

      def self.validate_reasons(reasons_array)
        invalid_reasons = reasons_array.reject { |r| ORPHAN_REASONS.key?(r) }
        return if invalid_reasons.empty?

        Gitlab::AppLogger.warn("Unknown orphan reason(s): #{invalid_reasons.join(', ')}")
      end
      private_class_method :validate_reasons
    end
  end
end
