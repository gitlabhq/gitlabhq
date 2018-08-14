module Gitlab
  module Database
    module RenameReservedPathsMigration
      module V1
        class RenameBase
          include Gitlab::Database::ArelMethods

          attr_reader :paths, :migration

          delegate :update_column_in_batches,
                   :execute,
                   :replace_sql,
                   :quote_string,
                   :say,
                   to: :migration

          def initialize(paths, migration)
            @paths = paths
            @migration = migration
          end

          def path_patterns
            @path_patterns ||= paths.flat_map { |path| ["%/#{path}", path] }
          end

          def rename_path_for_routable(routable)
            old_path = routable.path
            old_full_path = routable.full_path
            # Only remove the last occurrence of the path name to get the parent namespace path
            namespace_path = remove_last_occurrence(old_full_path, old_path)
            new_path = rename_path(namespace_path, old_path)
            new_full_path = join_routable_path(namespace_path, new_path)

            perform_rename(routable, old_full_path, new_full_path)

            [old_full_path, new_full_path]
          end

          def perform_rename(routable, old_full_path, new_full_path)
            # skips callbacks & validations
            new_path = new_full_path.split('/').last
            routable.class.where(id: routable)
              .update_all(path: new_path)

            rename_routes(old_full_path, new_full_path)
          end

          def rename_routes(old_full_path, new_full_path)
            routes = Route.arel_table

            quoted_old_full_path = quote_string(old_full_path)
            quoted_old_wildcard_path = quote_string("#{old_full_path}/%")

            filter = if Database.mysql?
                       "lower(routes.path) = lower('#{quoted_old_full_path}') "\
                       "OR routes.path LIKE '#{quoted_old_wildcard_path}'"
                     else
                       "routes.id IN "\
                       "( SELECT routes.id FROM routes WHERE lower(routes.path) = lower('#{quoted_old_full_path}') "\
                       "UNION SELECT routes.id FROM routes WHERE routes.path ILIKE '#{quoted_old_wildcard_path}' )"
                     end

            replace_statement = replace_sql(Route.arel_table[:path],
                                            old_full_path,
                                            new_full_path)

            update = arel_update_manager
              .table(routes)
              .set([[routes[:path], replace_statement]])
              .where(Arel::Nodes::SqlLiteral.new(filter))

            execute(update.to_sql)
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
            unless File.directory?(old_path)
              say "#{old_path} doesn't exist, skipping"
              return
            end

            new_path = File.join(directory, new_relative_path)
            FileUtils.mv(old_path, new_path)
          end

          def remove_cached_html_for_projects(project_ids)
            project_ids.each do |project_id|
              update_column_in_batches(:projects, :description_html, nil) do |table, query|
                query.where(table[:id].eq(project_id))
              end

              update_column_in_batches(:issues, :description_html, nil) do |table, query|
                query.where(table[:project_id].eq(project_id))
              end

              update_column_in_batches(:merge_requests, :description_html, nil) do |table, query|
                query.where(table[:target_project_id].eq(project_id))
              end

              update_column_in_batches(:notes, :note_html, nil) do |table, query|
                query.where(table[:project_id].eq(project_id))
              end

              update_column_in_batches(:milestones, :description_html, nil) do |table, query|
                query.where(table[:project_id].eq(project_id))
              end
            end
          end

          def track_rename(type, old_path, new_path)
            key = redis_key_for_type(type)
            Gitlab::Redis::SharedState.with do |redis|
              redis.lpush(key, [old_path, new_path].to_json)
              redis.expire(key, 2.weeks.to_i)
            end
            say "tracked rename: #{key}: #{old_path} -> #{new_path}"
          end

          def reverts_for_type(type)
            key = redis_key_for_type(type)

            Gitlab::Redis::SharedState.with do |redis|
              failed_reverts = []

              while rename_info = redis.lpop(key)
                path_before_rename, path_after_rename = JSON.parse(rename_info)
                say "renaming #{type} from #{path_after_rename} back to #{path_before_rename}"
                begin
                  yield(path_before_rename, path_after_rename)
                rescue StandardError => e
                  failed_reverts << rename_info
                  say "Renaming #{type} from #{path_after_rename} back to "\
                      "#{path_before_rename} failed. Review the error and try "\
                      "again by running the `down` action. \n"\
                      "#{e.message}: \n #{e.backtrace.join("\n")}"
                end
              end

              failed_reverts.each { |rename_info| redis.lpush(key, rename_info) }
            end
          end

          def redis_key_for_type(type)
            "rename:#{migration.name}:#{type}"
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
end
