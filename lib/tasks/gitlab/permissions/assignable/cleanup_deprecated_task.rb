# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Assignable
        class CleanupDeprecatedTask
          BBM_DOCS_GLOB = Rails.root.join('db/docs/batched_background_migrations/*.yml')
          POST_MIGRATE_DIR = Rails.root.join('db/post_migrate')
          BBM_WORKER_NAMESPACE = 'Gitlab::BackgroundMigration'

          def run
            current_milestone = Gem::Version.new(::Gitlab.current_milestone)
            deletable = deletable_files(current_milestone)

            if deletable.empty?
              puts "No deprecated permission files are ready for deletion."
              return
            end

            deletable.each do |path|
              rel = Pathname.new(path).relative_path_from(Rails.root)
              File.delete(path)
              puts "  [deleted] #{rel}"
            end

            puts "\n#{deletable.size} file(s) deleted."
          end

          private

          def deletable_files(current_milestone)
            safe_old_names = finalized_old_names(current_milestone)
            return [] if safe_old_names.empty?

            ::Authz::PermissionGroups::Assignable.definitions
              .select { |p| p.deprecated? && safe_old_names.include?(p.name) }
              .map(&:source_file)
          end

          def finalized_old_names(current_milestone)
            Set.new.tap do |names|
              bbm_docs_finalized_before(current_milestone).each do |doc|
                renames = renames_for_job(doc[:migration_job_name].to_s)
                renames&.each_key { |old_name| names << old_name }
              end
            end
          end

          def bbm_docs_finalized_before(current_milestone)
            Dir.glob(BBM_DOCS_GLOB).filter_map do |path|
              doc = YAML.safe_load(File.read(path))&.deep_symbolize_keys
              next unless doc&.dig(:finalized_by).present?

              finalize_milestone = milestone_for_post_migrate(doc[:finalized_by].to_s)
              next unless finalize_milestone
              next unless Gem::Version.new(finalize_milestone) < current_milestone

              doc
            end
          end

          def milestone_for_post_migrate(version)
            files = Dir.glob(POST_MIGRATE_DIR.join("#{version}_*.rb"))
            return unless files.one?

            content = File.read(files.first)
            match = content.match(/^\s+milestone\s+['"](\d+\.\d+)['"]/)
            match[1] if match
          end

          def renames_for_job(job_class_name)
            return if job_class_name.blank?

            klass = "#{BBM_WORKER_NAMESPACE}::#{job_class_name}".safe_constantize
            return unless klass&.const_defined?(:RENAMES)

            klass::RENAMES
          end
        end
      end
    end
  end
end
