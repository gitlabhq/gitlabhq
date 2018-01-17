module EE
  module ProjectTeam
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :add_users
    def add_users(users, access_level, current_user: nil, expires_at: nil)
      return false if group_member_lock

      super
    end

    override :add_user
    def add_user(user, access_level, current_user: nil, expires_at: nil)
      return false if group_member_lock

      super
    end

    private

    def group_member_lock
      group && group.membership_lock
    end
  end
end
