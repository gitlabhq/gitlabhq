# frozen_string_literal: true

module Users
  # Service for refreshing the authorized projects of a user.
  #
  # This particular service class can not be used to update data for the same
  # user concurrently. Doing so could lead to an incorrect state. To ensure this
  # doesn't happen a caller must synchronize access (e.g. using
  # `Gitlab::ExclusiveLease`).
  #
  # Usage:
  #
  #     user = User.find_by(username: 'alice')
  #     service = Users::RefreshAuthorizedProjectsService.new(some_user)
  #     service.execute
  class RefreshAuthorizedProjectsService
    attr_reader :user, :source

    # user - The User for which to refresh the authorized projects.
    def initialize(user, source: nil, incorrect_auth_found_callback: nil, missing_auth_found_callback: nil)
      @user = user
      @source = source
      @incorrect_auth_found_callback = incorrect_auth_found_callback
      @missing_auth_found_callback = missing_auth_found_callback
    end

    # This method returns the updated User object.
    def execute
      # We need an up to date User object that has access to all relations that
      # may have been created earlier.
      user.reset

      remove, add = AuthorizedProjectUpdate::FindRecordsDueForRefreshService.new(
        user,
        source: source,
        incorrect_auth_found_callback: incorrect_auth_found_callback,
        missing_auth_found_callback: missing_auth_found_callback
      ).execute

      update_authorizations(remove, add)
    end

    # Updates the list of authorizations for the current user.
    #
    # remove - The project IDs of the authorization rows to remove.
    # add - Rows to insert in the form `[{ user_id: user_id, project_id: project_id, access_level: access_level}, ...]`
    def update_authorizations(remove = [], add = [])
      authorization_changes = ProjectAuthorizations::Changes.new do |changes|
        changes.add(add)
        changes.remove_projects_for_user(user, remove)
      end.apply!

      user.update!(project_authorizations_recalculated_at: Time.zone.now) if remove.any? || add.any?

      log_refresh_details(authorization_changes, remove, add)

      # Since we batch insert authorization rows, Rails' associations may get
      # out of sync. As such we force a reload of the User object.
      user.reset
    end

    private

    attr_reader :incorrect_auth_found_callback, :missing_auth_found_callback

    def log_refresh_details(changes, remove, add)
      record_safety_net_refresh_metrics(changes)

      Gitlab::AppJsonLogger.info(
        event: 'authorized_projects_refresh',
        user_id: user.id,
        'authorized_projects_refresh.source': source,
        # `source` is always the class of the worker that ended up running this
        # service, which for the safety-net workers is the same regardless of why
        # they were triggered. `trigger` instead carries the originally
        # enqueuing caller (see `related_class` propagation in
        # `UserProjectAccessChangedService`/`UserRefreshOverUserRangeWorker`)
        'authorized_projects_refresh.trigger': refresh_trigger,
        'authorized_projects_refresh.rows_deleted_count': changes.rows_deleted,
        'authorized_projects_refresh.rows_added_count': changes.rows_added,
        # most often there's only a few entries in remove and add, but limit it to the first 5
        # entries to avoid flooding the logs
        'authorized_projects_refresh.rows_deleted_slice': remove.first(5),
        # Logged arrays should have uniformly typed values.
        'authorized_projects_refresh.rows_added_slice':
          add.first(5).map { |row| row.values_at(:user_id, :project_id, :access_level) }
      )
    end

    def refresh_trigger
      Gitlab::ApplicationContext.current_context_attribute('meta.related_class').presence
    end

    def record_safety_net_refresh_metrics(changes)
      refresh_purpose = Gitlab::ApplicationContext.current_context_attribute(
        'meta.authorized_projects_refresh_purpose'
      )

      return unless refresh_purpose == UserProjectAccessChangedService::SAFETY_NET_REFRESH_PURPOSE

      labels = { trigger: refresh_trigger.to_s }

      counter = Gitlab::Metrics.counter(
        :gitlab_authorized_projects_safety_net_refresh_rows_total,
        'Total number of project_authorizations rows added or deleted by a safety-net refresh'
      )

      counter.increment(labels.merge(direction: 'deleted'), changes.rows_deleted) if changes.rows_deleted > 0
      counter.increment(labels.merge(direction: 'added'), changes.rows_added) if changes.rows_added > 0
    end
  end
end
