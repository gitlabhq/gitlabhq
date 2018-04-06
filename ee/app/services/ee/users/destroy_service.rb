module EE
  module Users
    module DestroyService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(user, options = {})
        super(user, options) do |delete_user|
          mirror_cleanup(delete_user)
        end
      end

      def mirror_cleanup(user)
        user_mirrors = ::Project.where(mirror_user: user)

        user_mirrors.find_each do |mirror|
          new_mirror_user = first_mirror_owner(user, mirror)

          mirror.update_attributes(mirror_user: new_mirror_user)
          ::NotificationService.new.project_mirror_user_changed(new_mirror_user, user.name, mirror)
        end
      end

      private

      def first_mirror_owner(user, mirror)
        mirror_owners = mirror.team.owners
        mirror_owners -= [user]

        mirror_owners.first
      end
    end
  end
end
