# frozen_string_literal: true

module Members
  class ActivityService
    include ExclusiveLeaseGuard

    def initialize(user, namespace)
      @user = user
      @namespace = namespace&.root_ancestor
    end

    def execute
      return ServiceResponse.error(message: 'Invalid params') unless namespace && user

      try_obtain_lease do
        find_members

        break unless members.any?

        # Rails throws away the `in_hierarchy` scope, so this generates a WHERE IN instead
        # rubocop:disable CodeReuse/ActiveRecord -- Scope is lost
        Member.where(id: members.select(:id)).touch_all(:last_activity_on)
        # rubocop:enable CodeReuse/ActiveRecord
      end

      ServiceResponse.success(message: 'Member activity tracked')
    end

    private

    attr_reader :user, :namespace, :members

    def lease_timeout
      (Time.current.end_of_day - Time.current).to_i
    end

    def lease_key
      "members_activity_event:#{namespace.id}:#{user.id}"
    end

    # Used by ExclusiveLeaseGuard
    # Overriding value as we only release the lease
    # before the timeout if there was no members found, in order to prevent multiple
    # updates in a short span of time but allow an update if the member is added later
    def lease_release?
      members.empty?
    end

    def find_members
      @members = Member.in_hierarchy(namespace).with_user(user).no_activity_today
    end
  end
end
