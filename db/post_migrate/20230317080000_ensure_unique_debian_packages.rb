# frozen_string_literal: true

class EnsureUniqueDebianPackages < Gitlab::Database::Migration[2.1]
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Package < MigrationRecord
    include EachBatch

    self.table_name = 'packages_packages'

    enum package_type: { debian: 9 }

    enum status: { pending_destruction: 4 }
  end

  def up
    Package.distinct_each_batch(column: :project_id) do |package_projects|
      project_ids = package_projects.pluck(:project_id)
      duplicates = Package.debian
                          .not_pending_destruction
                          .where(project_id: project_ids)
                          .select('project_id, name, version, MAX(id) as last_id')
                          .group(:project_id, :name, :version)
                          .having('count(id) > 1')
      loop do
        duplicates.limit(BATCH_SIZE).each do |duplicate|
          Package.debian
                .not_pending_destruction
                .where(
                  project_id: duplicate.project_id,
                  name: duplicate.name,
                  version: duplicate.version,
                  id: ..duplicate.last_id - 1
                ).update_all status: :pending_destruction
        end
        break unless duplicates.exists?
      end
    end
  end

  def down
    # nothing to do
  end
end
