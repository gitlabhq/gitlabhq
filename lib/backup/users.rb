module Backup
  class Users
    attr_reader :user_dump_file

    def initialize
      @user_dump_file = File.join(Gitlab.config.backup.path, 'users.csv')
    end

    def dump
      CSV.open(user_dump_file, "w") do |csv|
        csv << ["email", "name", "admin", "projects_limit", "username", "can_create_group", "state"]
        User.all.each do |u|
          csv << [u.email, u.name, u.admin, u.projects_limit, u.username, u.can_create_group, u.state]
        end
      end
    end
  end
end
