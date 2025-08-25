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

      notified_inactive_projects = Gitlab::DormantProjectsDeletionWarningTracker.notified_projects

      project_id = last_processed_project_id

      Project.where('projects.id > ?', project_id).each_batch(of: 100) do |batch| # rubocop: disable CodeReuse/ActiveRecord
        inactive_projects = batch.inactive.not_aimed_for_deletion

        inactive_projects.each do |project|
          if over_time?
            save_last_processed_project_id(project.id)
            raise TimeoutError
          end

          organization_admin_bot = admin_bot_for_organization_id(project.organization_id)

          with_context(project: project, user: organization_admin_bot) do
            deletion_warning_email_sent_on = notified_inactive_projects["project:#{project.id}"]

            if deletion_warning_email_sent_on.blank?
              send_notification(project)
              log_audit_event(project, organization_admin_bot)
            elsif grace_period_is_over?(deletion_warning_email_sent_on)
              Gitlab::DormantProjectsDeletionWarningTracker.new(project.id).reset
              delete_project(project, organization_admin_bot)
            end
          end
        end
      end
      reset_last_processed_project_id
    rescue TimeoutError
      # no-op
    end

    private

    def grace_period_is_over?(deletion_warning_email_sent_on)
      deletion_warning_email_sent_on < grace_months_after_deletion_notification.ago
    end

    def grace_months_after_deletion_notification
      strong_memoize(:grace_months_after_deletion_notification) do
        (::Gitlab::CurrentSettings.inactive_projects_delete_after_months -
          ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months).months
      end
    end

    def deletion_date
      grace_months_after_deletion_notification.from_now.to_date.to_s
    end

    def delete_project(project, user)
      ::Projects::MarkForDeletionService.new(project, user, {}).execute
    end

    def send_notification(project)
      ::Projects::InactiveProjectsDeletionNotificationWorker.perform_async(project.id, deletion_date)
    end

    def log_audit_event(_project, _user)
      # Defined in EE
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

    def admin_bot_for_organization_id(organization_id)
      @admin_bots ||= {}
      @admin_bots[organization_id] ||= Users::Internal.for_organization(organization_id).admin_bot
    end
  end
end

Projects::InactiveProjectsDeletionCronWorker.prepend_mod
