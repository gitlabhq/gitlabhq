class RemovePeriodsAtEndsOfUsernames < ActiveRecord::Migration
  include Gitlab::ShellAdapter

  class Namespace < ActiveRecord::Base
    class << self
      def find_by_path_or_name(path)
        find_by("lower(path) = :path OR lower(name) = :path", path: path.downcase)
      end

      def clean_path(path)
        path = path.dup
        # Get the email username by removing everything after an `@` sign.
        path.gsub!(/@.*\z/,             "")
        # Usernames can't end in .git, so remove it.
        path.gsub!(/\.git\z/,           "")
        # Remove dashes at the start of the username.
        path.gsub!(/\A-+/,              "")
        # Remove periods at the end of the username.
        path.gsub!(/\.+\z/,             "")
        # Remove everything that's not in the list of allowed characters.
        path.gsub!(/[^a-zA-Z0-9_\-\.]/, "")

        # Users with the great usernames of "." or ".." would end up with a blank username.
        # Work around that by setting their username to "blank", followed by a counter.
        path = "blank" if path.blank?

        counter = 0
        base = path
        while Namespace.find_by_path_or_name(path)
          counter += 1
          path = "#{base}#{counter}"
        end

        path
      end
    end
  end

  def up
    changed_paths = {}

    select_all("SELECT id, username FROM users WHERE username LIKE '%.'").each do |user|
      username_was = user["username"]
      username = Namespace.clean_path(username_was)
      changed_paths[username_was] = username

      username = quote_string(username)
      execute "UPDATE users SET username = '#{username}' WHERE id = #{user["id"]}"
      execute "UPDATE namespaces SET path = '#{username}', name = '#{username}' WHERE type IS NULL AND owner_id = #{user["id"]}"
    end

    select_all("SELECT id, path FROM namespaces WHERE type = 'Group' AND path LIKE '%.'").each do |group|
      path_was = group["path"]
      path = Namespace.clean_path(path_was)
      changed_paths[path_was] = path

      path = quote_string(path)
      execute "UPDATE namespaces SET path = '#{path}' WHERE id = #{group["id"]}"
    end

    changed_paths.each do |path_was, path|
      # Don't attempt to move if original path only contains periods.
      next if path_was =~ /\A\.+\z/

      if gitlab_shell.mv_namespace(path_was, path)
        # If repositories moved successfully we need to remove old satellites
        # and send update instructions to users.
        # However we cannot allow rollback since we moved namespace dir
        # So we basically we mute exceptions in next actions
        begin
          gitlab_shell.rm_satellites(path_was)
          # We cannot send update instructions since models and mailers
          # can't safely be used from migrations as they may be written for 
          # later versions of the database.
          # send_update_instructions
        rescue
          # Returning false does not rollback after_* transaction but gives
          # us information about failing some of tasks
          false
        end
      else
        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise Exception.new('namespace directory cannot be moved')
      end
    end
  end
end
