# frozen_string_literal: true

module Users
  class ActivityService
    LEASE_TIMEOUT = 1.minute.to_i

    def initialize(author:, namespace: nil, project: nil)
      @user = if author.respond_to?(:username)
                author
              elsif author.respond_to?(:user)
                author.user
              end

      @user = nil unless user.is_a?(User)
      @namespace = namespace
      @project = project
    end

    def execute
      return unless user
      return if user.last_activity_on == Date.today

      ::Gitlab::Database::LoadBalancing::SessionMap.current(user.load_balancer)
              .without_sticky_writes { record_activity }
    end

    private

    attr_reader :user, :namespace, :project

    def record_activity
      return if Gitlab::Database.read_only?

      lease = Gitlab::ExclusiveLease.new("activity_service:#{user.id}", timeout: LEASE_TIMEOUT)
      # Skip transaction checks for exclusive lease as it is breaking system specs.
      # See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/441536
      return unless Gitlab::ExclusiveLease.skipping_transaction_check { lease.try_obtain }

      user.update_attribute(:last_activity_on, Date.today)

      Gitlab::UsageDataCounters::HLLRedisCounter.track_event('unique_active_user', values: user.id)

      Gitlab::Tracking.event(
        'Users::ActivityService',
        'perform_action',
        user: user,
        namespace: namespace,
        project: project,
        label: 'redis_hll_counters.manage.unique_active_users_monthly',
        context: [
          Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: 'unique_active_user').to_context
        ]
      )
    end
  end
end
