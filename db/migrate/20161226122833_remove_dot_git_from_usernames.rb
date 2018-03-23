# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDotGitFromUsernames < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    invalid_users.each do |user|
      id = user['id']
      namespace_id = user['namespace_id']
      path_was = user['username']
      path_was_wildcard = quote_string("#{path_was}/%")
      path = quote_string(new_path(path_was))

      move_namespace(namespace_id, path_was, path)

      begin
        execute "UPDATE routes SET path = '#{path}' WHERE source_type = 'Namespace' AND source_id = #{namespace_id}"
        execute "UPDATE namespaces SET path = '#{path}' WHERE id = #{namespace_id}"
        execute "UPDATE users SET username = '#{path}' WHERE id = #{id}"

        select_all("SELECT id, path FROM routes WHERE path LIKE '#{path_was_wildcard}'").each do |route|
          new_path = "#{path}/#{route['path'].split('/').last}"
          execute "UPDATE routes SET path = '#{new_path}' WHERE id = #{route['id']}"
        end
      rescue => e
        say("Couldn't update routes for path #{path_was} to #{path}")
        # Move namespace back
        move_namespace(namespace_id, path, path_was)

        raise e
      end
    end
  end

  def down
    # nothing to do here
  end

  private

  def invalid_users
    select_all("SELECT u.id, u.username, n.path AS namespace_path, n.id AS namespace_id FROM users u
                INNER JOIN namespaces n ON n.owner_id = u.id
                WHERE n.type is NULL AND n.path LIKE '%.git'")
  end

  def route_exists?(path)
    select_all("SELECT id, path FROM routes WHERE path = '#{quote_string(path)}'").present?
  end

  def path_exists?(path, repository_storage_path)
    repository_storage_path && gitlab_shell.exists?(repository_storage_path, path)
  end

  # Accepts invalid path like test.git and returns test_git or
  # test_git1 if test_git already taken
  def new_path(path)
    # To stay closer with original name and reduce risk of duplicates
    # we rename suffix instead of removing it
    path = path.sub(/\.git\z/, '_git')

    check_routes(path.dup, 0, path)
  end

  def check_routes(base, counter, path)
    route_exists = route_exists?(path)

    Gitlab.config.repositories.storages.each_value do |storage|
      if route_exists || path_exists?(path, storage.legacy_disk_path)
        counter += 1
        path = "#{base}#{counter}"

        return check_routes(base, counter, path)
      end
    end

    path
  end

  def move_namespace(namespace_id, path_was, path)
    repository_storage_paths = select_all("SELECT distinct(repository_storage) FROM projects WHERE namespace_id = #{namespace_id}").map do |row|
      Gitlab.config.repositories.storages[row['repository_storage']].legacy_disk_path
    end.compact

    # Move the namespace directory in all storages paths used by member projects
    repository_storage_paths.each do |repository_storage_path|
      # Ensure old directory exists before moving it
      gitlab_shell.add_namespace(repository_storage_path, path_was)

      unless gitlab_shell.mv_namespace(repository_storage_path, path_was, path)
        Rails.logger.error "Exception moving path #{repository_storage_path} from #{path_was} to #{path}"

        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise Exception.new('namespace directory cannot be moved')
      end
    end

    begin
      Gitlab::UploadsTransfer.new.rename_namespace(path_was, path)
    rescue => e
      if path.nil?
        say("Couldn't find a storage path for #{namespace_id}, #{path_was} -- skipping")
      else
        raise e
      end
    end
  end
end
