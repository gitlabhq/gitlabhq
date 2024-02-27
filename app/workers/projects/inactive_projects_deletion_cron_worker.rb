# frozen_string_literal: true

module Projects
  class InactiveProjectsDeletionCronWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize
    include CronjobQueue

    idempotent!
    data_consistency :always
    feature_category :groups_and_projects
    urgency :low

    # This cron worker is executed at an interval of 10 minutes.
    # Maximum run time is kept as 4 minutes to avoid breaching maximum allowed execution latency of 5 minutes.
    MAX_RUN_TIME = 4.minutes
    LAST_PROCESSED_INACTIVE_PROJECT_REDIS_KEY = 'last_processed_inactive_project_id'

    TimeoutError = Class.new(StandardError)

    def perform
      return unless ::Gitlab::CurrentSettings.delete_inactive_projects?

      @start_time ||= ::Gitlab::Metrics::System.monotonic_time
      admin_bot = ::Users::Internal.admin_bot

      return unless admin_bot

      notified_inactive_projects = Gitlab::InactiveProjectsDeletionWarningTracker.notified_projects

      project_id = last_processed_project_id

      Project.where('projects.id > ?', project_id).each_batch(of: 100) do |batch| # rubocop: disable CodeReuse/ActiveRecord
        inactive_projects = batch.inactive.without_deleted

        inactive_projects.each do |project|
          if over_time?
            save_last_processed_project_id(project.id)
            raise TimeoutError
          end

          with_context(project: project, user: admin_bot) do
            deletion_warning_email_sent_on = notified_inactive_projects["project:#{project.id}"]

            if send_deletion_warning_email?(deletion_warning_email_sent_on, project)
              send_notification(project, admin_bot)
            elsif deletion_warning_email_sent_on && delete_due_to_inactivity?(deletion_warning_email_sent_on)
              Gitlab::InactiveProjectsDeletionWarningTracker.new(project.id).reset
              delete_project(project, admin_bot)
            end
          end
        end
      end
      reset_last_processed_project_id
    rescue TimeoutError
      # no-op
    end

    private

    def grace_months_after_deletion_notification
      strong_memoize(:grace_months_after_deletion_notification) do
        (::Gitlab::CurrentSettings.inactive_projects_delete_after_months -
          ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months).months
      end
    end

    def send_deletion_warning_email?(deletion_warning_email_sent_on, project)
      deletion_warning_email_sent_on.blank?
    end

    def delete_due_to_inactivity?(deletion_warning_email_sent_on)
      deletion_warning_email_sent_on < grace_months_after_deletion_notification.ago
    end

    def deletion_date
      grace_months_after_deletion_notification.from_now.to_date.to_s
    end

    def delete_project(project, user)
      ::Projects::DestroyService.new(project, user, {}).async_execute
    end

    def send_notification(project, user)
      ::Projects::InactiveProjectsDeletionNotificationWorker.perform_async(project.id, deletion_date)
    end

    def over_time?
      (::Gitlab::Metrics::System.monotonic_time - @start_time) > MAX_RUN_TIME
    end

    def save_last_processed_project_id(project_id)
      with_redis do |redis|
        redis.set(LAST_PROCESSED_INACTIVE_PROJECT_REDIS_KEY, project_id)
      end
    end

    def last_processed_project_id
      with_redis do |redis|
        redis.get(LAST_PROCESSED_INACTIVE_PROJECT_REDIS_KEY).to_i
      end
    end

    def reset_last_processed_project_id
      with_redis do |redis|
        redis.del(LAST_PROCESSED_INACTIVE_PROJECT_REDIS_KEY)
      end
    end

    def with_redis(&block)
      Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end

Projects::InactiveProjectsDeletionCronWorker.prepend_mod
