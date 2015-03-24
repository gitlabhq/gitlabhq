class RemovePeriodsAtEndsOfUsernames < ActiveRecord::Migration
  class Namespace < ActiveRecord::Base
    class << self
      def by_path(path)
        where('lower(path) = :value', value: path.downcase).first
      end

      def clean_path(path)
        path.gsub!(/@.*\z/,             "")
        path.gsub!(/\.git\z/,           "")
        path.gsub!(/\A-/,               "")
        path.gsub!(/.\z/,               "")
        path.gsub!(/[^a-zA-Z0-9_\-\.]/, "")

        counter = 0
        base = path
        while Namespace.by_path(path).present?
          counter += 1
          path = "#{base}#{counter}"
        end

        path
      end
    end
  end

  def up
    select_all("SELECT id, username FROM users WHERE username LIKE '%.'").each do |user|
      username = quote_string(Namespace.clean_path(user["username"]))
      execute "UPDATE users SET username = '#{username}' WHERE id = #{user["id"]}"
      execute "UPDATE namespaces SET path = '#{username}', name = '#{username}' WHERE type = NULL AND owner_id = #{user["id"]}"
    end

    select_all("SELECT id, path FROM namespaces WHERE type = 'Group' AND path LIKE '%.'").each do |group|
      path = quote_string(Namespace.clean_path(group["path"]))
      execute "UPDATE namespaces SET path = '#{path}' WHERE id = #{group["id"]}"
    end
  end
end
