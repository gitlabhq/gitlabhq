module Gitlab
  module Database
    module RenameReservedPathsMigration
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

          move_repository(project, old_full_path, new_full_path)
          move_repository(project, "#{old_full_path}.wiki", "#{new_full_path}.wiki")
          move_uploads(old_full_path, new_full_path)
          move_pages(old_full_path, new_full_path)
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
