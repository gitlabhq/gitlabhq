module Users
  class BlockContext < Users::BaseContext
    def execute
      User.transaction do
        user.block

        # Remove user from all projects and
        user.users_projects.find_each do |membership|
          return false unless membership.destroy
        end

        # Remove user from all projects and
        user.user_teams.find_each do |membership|
          return false unless membership.destroy
        end
      end
    end
  end
end
