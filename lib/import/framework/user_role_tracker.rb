# frozen_string_literal: true

module Import
  module Framework
    # Tracks the access level of a user in the context of an import operation.
    #
    # Emits a tracking event with the user's role in the destination namespace,
    # treating the user as an owner when no parent namespace exists or the user
    # is not a member of the destination group.
    class UserRoleTracker
      def initialize(current_user:, tracking_class_name:, import_type:)
        @current_user = current_user
        @tracking_class_name = tracking_class_name
        @import_type = import_type
      end

      def track(destination_namespace)
        Gitlab::Tracking.event(
          tracking_class_name,
          'create',
          label: 'import_access_level',
          user: current_user,
          extra: { user_role: user_role(destination_namespace), import_type: import_type }
        )
      end

      private

      attr_reader :tracking_class_name, :import_type, :current_user

      def user_role(destination_namespace)
        return owner_role unless destination_namespace.present?

        namespace = Namespace.find_by_full_path(destination_namespace)
        # If there is no parent namespace we assume user will be group creator/owner
        return owner_role unless namespace
        return owner_role unless namespace.group_namespace?

        membership = current_user.group_members.find_by(source_id: namespace.id) # rubocop:disable CodeReuse/ActiveRecord -- existing violation

        return 'Not a member' unless membership

        Gitlab::Access.human_access(membership.access_level)
      end

      def owner_role
        Gitlab::Access.human_access(Gitlab::Access::OWNER)
      end
    end
  end
end
