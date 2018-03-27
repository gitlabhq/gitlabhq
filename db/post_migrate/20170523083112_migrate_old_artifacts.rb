class MigrateOldArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # This uses special heuristic to find potential candidates for data migration
  # Read more about this here: https://gitlab.com/gitlab-org/gitlab-ce/issues/32036#note_30422345

  def up
    builds_with_artifacts.find_each do |build|
      build.migrate_artifacts!
    end
  end

  def down
  end

  private

  def builds_with_artifacts
    Build.with_artifacts
      .joins('JOIN projects ON projects.id = ci_builds.project_id')
      .where('ci_builds.id < ?', min_id)
      .where('projects.ci_id IS NOT NULL')
      .select('id', 'created_at', 'project_id', 'projects.ci_id AS ci_id')
  end

  def min_id
    Build.joins('JOIN projects ON projects.id = ci_builds.project_id')
      .where('projects.ci_id IS NULL')
      .pluck('coalesce(min(ci_builds.id), 0)')
      .first
  end

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'

    scope :with_artifacts, -> { where.not(artifacts_file: [nil, '']) }

    def migrate_artifacts!
      return unless File.exist?(source_artifacts_path)
      return if File.exist?(target_artifacts_path)

      ensure_target_path

      FileUtils.move(source_artifacts_path, target_artifacts_path)
    end

    private

    def source_artifacts_path
      @source_artifacts_path ||=
        File.join(Gitlab.config.artifacts.path,
          created_at.utc.strftime('%Y_%m'),
          ci_id.to_s, id.to_s)
    end

    def target_artifacts_path
      @target_artifacts_path ||=
        File.join(Gitlab.config.artifacts.path,
          created_at.utc.strftime('%Y_%m'),
          project_id.to_s, id.to_s)
    end

    def ensure_target_path
      directory = File.dirname(target_artifacts_path)
      FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
    end
  end
end
