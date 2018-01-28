module Gitlab
  module Database
    module RenameReservedPathsMigration
      module V1
        class RenameProjects < RenameBase
          include Gitlab::ShellAdapter

          def rename_projects
            projects_for_paths.each do |project|
              rename_project(project)
            end

            remove_cached_html_for_projects(projects_for_paths.map(&:id))
          end

          def rename_project(project)
            old_full_path, new_full_path = rename_path_for_routable(project)

            track_rename('project', old_full_path, new_full_path)

            move_project_folders(project, old_full_path, new_full_path)
          end

          def move_project_folders(project, old_full_path, new_full_path)
            unless project.hashed_storage?(:repository)
              move_repository(project, old_full_path, new_full_path)
              move_repository(project, "#{old_full_path}.wiki", "#{new_full_path}.wiki")
            end

            move_uploads(old_full_path, new_full_path) unless project.hashed_storage?(:attachments)
            move_pages(old_full_path, new_full_path)
          end

          def revert_renames
            reverts_for_type('project') do |path_before_rename, current_path|
              matches_path = MigrationClasses::Route.arel_table[:path].matches(current_path)
              project = MigrationClasses::Project.joins(:route)
                          .where(matches_path).first

              if project
                perform_rename(project, current_path, path_before_rename)

                move_project_folders(project, current_path, path_before_rename)
              else
                say "Couldn't rename project from #{current_path} back to "\
                    "#{path_before_rename}, project was renamed or no longer "\
                    "exists at the expected path."

              end
            end
          end

          def move_repository(project, old_path, new_path)
            unless gitlab_shell.mv_repository(project.repository_storage_path,
                                              old_path,
                                              new_path)
              Rails.logger.error "Error moving #{old_path} to #{new_path}"
            end
          end

          def projects_for_paths
            return @projects_for_paths if @projects_for_paths

            with_paths = MigrationClasses::Route.arel_table[:path]
                           .matches_any(path_patterns)

            @projects_for_paths = MigrationClasses::Project.joins(:route).where(with_paths)
          end
        end
      end
    end
  end
end
