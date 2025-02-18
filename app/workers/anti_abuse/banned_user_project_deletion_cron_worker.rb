# frozen_string_literal: true

module AntiAbuse
  class BannedUserProjectDeletionCronWorker
    include ApplicationWorker
    include CronjobQueue

    idempotent!
    feature_category :instance_resiliency
    data_consistency :sticky

    # Delay is set to double that of the AdjournedProjectsDeletionCronWorker
    DELAY = 20.seconds

    # Maximum run time is 4 minutes to avoid breaching maximum allowed execution latency of 5 minutes.
    MAX_RUN_TIME = 4.minutes

    # Ensure we don't overlap jobs by dividing the cron frequency by the delay
    PROJECT_DELETION_LIMIT = 1.day.to_i / DELAY
    BANNED_USER_CREATED_AT_THRESHOLD = 60.days
    PROCESSED_USER_BATCH_SIZE = 10_000

    LimitExceededError = Class.new(StandardError)

    def perform
      return unless Feature.enabled?(:delete_banned_user_projects, :instance, type: :gitlab_com_derisk)

      @start_time ||= ::Gitlab::Metrics::System.monotonic_time
      queued = 0
      current_user_id = nil
      user_ids = []

      banned_users_query.each_batch do |users|
        user_ids = users.map(&:id).sort

        projects_query(user_ids).each_batch(column: :creator_id, order_hint: :id) do |project_relation|
          projects = project_relation.sort_by(&:creator_id)

          projects.each_with_index do |project, index|
            raise LimitExceededError if queued >= PROJECT_DELETION_LIMIT || over_time?

            current_user_id = project.creator_id

            with_context(project: project) do
              AntiAbuse::BannedUserProjectDeletionWorker.perform_in(index * DELAY, project.id)
              log_event(project)
            end

            queued += 1
          end
        end

        update_processed_users(user_ids)
      end

    rescue LimitExceededError
      return unless current_user_id

      partially_processed = user_ids.take_while { |id| id < current_user_id }
      update_processed_users(partially_processed)
    end

    private

    def over_time?
      (::Gitlab::Metrics::System.monotonic_time - @start_time) > MAX_RUN_TIME
    end

    def banned_users_query
      Users::BannedUser.created_before(BANNED_USER_CREATED_AT_THRESHOLD.ago).without_deleted_projects.select(:user_id)
    end

    def update_processed_users(user_ids)
      return if user_ids.empty?

      Users::BannedUser.by_user_ids(user_ids).update_all(projects_deleted: true)
    end

    def projects_query(user_ids)
      Project.without_deleted.created_by(user_ids).id_in(owned_project_ids(user_ids)).select(:creator_id, :id)
    end

    def owned_project_ids(user_ids)
      ProjectAuthorization.owned_by(user_ids).select(:project_id)
    end

    def log_event(project)
      Gitlab::AppLogger.info(
        class: self.class.name,
        message: "Banned user project scheduled for deletion",
        project_id: project.id,
        full_path: project.full_path,
        banned_user_id: project.creator_id
      )
    end
  end
end
