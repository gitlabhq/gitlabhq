# frozen_string_literal: true

module Gitlab
  class InactiveProjectsDeletionWarningTracker
    include Gitlab::Utils::StrongMemoize

    attr_reader :project_id

    DELETION_TRACKING_REDIS_KEY = 'inactive_projects_deletion_warning_email_notified'

    # Redis key 'inactive_projects_deletion_warning_email_notified' is a hash. It stores the date when the
    # deletion warning notification email was sent for an inactive project. The fields and values look like:
    # {"project:1"=>"2022-04-22", "project:5"=>"2022-04-22", "project:7"=>"2022-04-25"}
    # @return [Hash]
    def self.notified_projects
      Gitlab::Redis::SharedState.with do |redis|
        redis.hgetall(DELETION_TRACKING_REDIS_KEY)
      end
    end

    def self.reset_all
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(DELETION_TRACKING_REDIS_KEY)
      end
    end

    def initialize(project_id)
      @project_id = project_id
    end

    def notified?
      Gitlab::Redis::SharedState.with do |redis|
        redis.hexists(DELETION_TRACKING_REDIS_KEY, "project:#{project_id}")
      end
    end

    def mark_notified
      Gitlab::Redis::SharedState.with do |redis|
        redis.hset(DELETION_TRACKING_REDIS_KEY, "project:#{project_id}", Date.current.to_s)
      end
    end

    def notification_date
      Gitlab::Redis::SharedState.with do |redis|
        redis.hget(DELETION_TRACKING_REDIS_KEY, "project:#{project_id}")
      end
    end

    def scheduled_deletion_date
      notif_date = notification_date
      if notif_date.present?
        (notif_date.to_date + grace_period_after_notification).to_s
      else
        grace_period_after_notification.from_now.to_date.to_s
      end
    end

    def reset
      Gitlab::Redis::SharedState.with do |redis|
        redis.hdel(DELETION_TRACKING_REDIS_KEY, "project:#{project_id}")
      end
    end

    private

    def grace_period_after_notification
      strong_memoize(:grace_period_after_notification) do
        (::Gitlab::CurrentSettings.inactive_projects_delete_after_months -
          ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months).months
      end
    end
  end
end
