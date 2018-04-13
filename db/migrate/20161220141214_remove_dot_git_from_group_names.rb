# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDotGitFromGroupNames < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    invalid_groups.each do |group|
      path_was = group['path']
      path_was_wildcard = quote_string("#{path_was}/%")
      path = quote_string(rename_path(path_was))

      move_namespace(group['id'], path_was, path)

      execute "UPDATE routes SET path = '#{path}' WHERE source_type = 'Namespace' AND source_id = #{group['id']}"
      execute "UPDATE namespaces SET path = '#{path}' WHERE id = #{group['id']}"

      select_all("SELECT id, path FROM routes WHERE path LIKE '#{path_was_wildcard}'").each do |route|
        new_path = "#{path}/#{route['path'].split('/').last}"
        execute "UPDATE routes SET path = '#{new_path}' WHERE id = #{route['id']}"
      end
    end
  end

  def down
    # nothing to do here
  end

  private

  def invalid_groups
    select_all("SELECT id, path FROM namespaces WHERE type = 'Group' AND path LIKE '%.git'")
  end

  def route_exists?(path)
    select_all("SELECT id, path FROM routes WHERE path = '#{quote_string(path)}'").present?
  end

  # Accepts invalid path like test.git and returns test_git or
  # test_git1 if test_git already taken
  def rename_path(path)
    # To stay closer with original name and reduce risk of duplicates
    # we rename suffix instead of removing it
    path = path.sub(/\.git\z/, '_git')

    counter = 0
    base = path

    while route_exists?(path)
      counter += 1
      path = "#{base}#{counter}"
    end

    path
  end

  def move_namespace(group_id, path_was, path)
    repository_storages = select_all("SELECT distinct(repository_storage) FROM projects WHERE namespace_id = #{group_id}").map do |row|
      Gitlab.config.repositories.storages[row['repository_storage']].legacy_disk_path
    end.compact

    # Move the namespace directory in all storages paths used by member projects
    repository_storages.each do |repository_storage|
      # Ensure old directory exists before moving it
      gitlab_shell.add_namespace(repository_storage, path_was)

      unless gitlab_shell.mv_namespace(repository_storage, path_was, path)
        Rails.logger.error "Exception moving on shard #{repository_storage} from #{path_was} to #{path}"

        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise Exception.new('namespace directory cannot be moved')
      end
    end

    Gitlab::UploadsTransfer.new.rename_namespace(path_was, path)
  end
end
