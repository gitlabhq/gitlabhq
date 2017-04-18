module Gitlab
  module Database
    module RenameReservedPathsMigration
      class RenameBase
        attr_reader :paths, :migration

        delegate :update_column_in_batches,
                 :replace_sql,
                 to: :migration

        def initialize(paths, migration)
          @paths = paths
          @migration = migration
        end

        def path_patterns
          @path_patterns ||= paths.map { |path| "%#{path}" }
        end

        def rename_path_for_routable(routable)
          old_path = routable.path
          old_full_path = routable.full_path
          # Only remove the last occurrence of the path name to get the parent namespace path
          namespace_path = remove_last_occurrence(old_full_path, old_path)
          new_path = rename_path(namespace_path, old_path)
          new_full_path = join_routable_path(namespace_path, new_path)

          # skips callbacks & validations
          routable.class.where(id: routable).
            update_all(path: new_path)

          rename_routes(old_full_path, new_full_path)

          [old_full_path, new_full_path]
        end

        def rename_routes(old_full_path, new_full_path)
          replace_statement = replace_sql(Route.arel_table[:path],
                                          old_full_path,
                                          new_full_path)

          update_column_in_batches(:routes, :path, replace_statement)  do |table, query|
            query.where(MigrationClasses::Route.arel_table[:path].matches("#{old_full_path}%"))
          end
        end

        def rename_path(namespace_path, path_was)
          counter = 0
          path = "#{path_was}#{counter}"

          while route_exists?(join_routable_path(namespace_path, path))
            counter += 1
            path = "#{path_was}#{counter}"
          end

          path
        end

        def remove_last_occurrence(string, pattern)
          string.reverse.sub(pattern.reverse, "").reverse
        end

        def join_routable_path(namespace_path, top_level)
          if namespace_path.present?
            File.join(namespace_path, top_level)
          else
            top_level
          end
        end

        def route_exists?(full_path)
          MigrationClasses::Route.where(Route.arel_table[:path].matches(full_path)).any?
        end

        def move_pages(old_path, new_path)
          move_folders(pages_dir, old_path, new_path)
        end

        def move_uploads(old_path, new_path)
          return unless file_storage?

          move_folders(uploads_dir, old_path, new_path)
        end

        def move_folders(directory, old_relative_path, new_relative_path)
          old_path = File.join(directory, old_relative_path)
          return unless File.directory?(old_path)

          new_path = File.join(directory, new_relative_path)
          FileUtils.mv(old_path, new_path)
        end

        def file_storage?
          CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
        end

        def uploads_dir
          File.join(CarrierWave.root, "uploads")
        end

        def pages_dir
          Settings.pages.path
        end
      end
    end
  end
end
