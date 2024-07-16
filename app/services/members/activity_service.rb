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
        @member = Member.in_hierarchy(namespace).with_user(user).first

        break unless member
        break if member.last_activity_on.today?

        member.touch(:last_activity_on)
      end

      ServiceResponse.success(message: 'Member activity tracked')
    end

    private

    attr_reader :user, :namespace, :member

    def lease_timeout
      (Time.current.end_of_day - Time.current).to_i
    end

    def lease_key
      "members_activity_event:#{namespace.id}:#{user.id}"
    end

    # Used by ExclusiveLeaseGuard
    # Overriding value as we only release the lease
    # before the timeout if there was no member found, in order to prevent multiple
    # updates in a short span of time but allow an update if the member is added later
    def lease_release?
      !member.present?
    end
  end
end
