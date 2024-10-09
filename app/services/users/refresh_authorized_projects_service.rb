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

    LEASE_TIMEOUT = 1.minute.to_i

    # user - The User for which to refresh the authorized projects.
    def initialize(user, source: nil, incorrect_auth_found_callback: nil, missing_auth_found_callback: nil)
      @user = user
      @source = source
      @incorrect_auth_found_callback = incorrect_auth_found_callback
      @missing_auth_found_callback = missing_auth_found_callback

      @start_time = current_monotonic_time
      @duration_statistics = {}
    end

    def execute
      lease_key = "refresh_authorized_projects:#{user.id}"
      lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT)

      until uuid = lease.try_obtain
        # Keep trying until we obtain the lease. If we don't do so we may end up
        # not updating the list of authorized projects properly. To prevent
        # hammering Redis too much we'll wait for a bit between retries.
        sleep(0.1)
      end

      reset_timer_and_store_duration(:obtain_redis_lease)

      begin
        # We need an up to date User object that has access to all relations that
        # may have been created earlier. The only way to ensure this is to reload
        # the User object.
        user.reset
        execute_without_lease
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, uuid)
      end
    end

    # This method returns the updated User object.
    def execute_without_lease
      remove, add = AuthorizedProjectUpdate::FindRecordsDueForRefreshService.new(
        user,
        source: source,
        incorrect_auth_found_callback: incorrect_auth_found_callback,
        missing_auth_found_callback: missing_auth_found_callback
      ).execute

      reset_timer_and_store_duration(:find_records_due_for_refresh)

      update_authorizations(remove, add)
    end

    # Updates the list of authorizations for the current user.
    #
    # remove - The project IDs of the authorization rows to remove.
    # add - Rows to insert in the form `[{ user_id: user_id, project_id: project_id, access_level: access_level}, ...]`
    def update_authorizations(remove = [], add = [])
      ProjectAuthorizations::Changes.new do |changes|
        changes.add(add)
        changes.remove_projects_for_user(user, remove)
      end.apply!

      user.update!(project_authorizations_recalculated_at: Time.zone.now) if remove.any? || add.any?

      reset_timer_and_store_duration(:update_authorizations)

      log_refresh_details(remove, add)

      # Since we batch insert authorization rows, Rails' associations may get
      # out of sync. As such we force a reload of the User object.
      user.reset
    end

    private

    attr_reader :incorrect_auth_found_callback, :missing_auth_found_callback

    def log_refresh_details(remove, add)
      Gitlab::AppJsonLogger.info(
        event: 'authorized_projects_refresh',
        user_id: user.id,
        'authorized_projects_refresh.source': source,
        'authorized_projects_refresh.rows_deleted_count': remove.length,
        'authorized_projects_refresh.rows_added_count': add.length,
        # most often there's only a few entries in remove and add, but limit it to the first 5
        # entries to avoid flooding the logs
        'authorized_projects_refresh.rows_deleted_slice': remove.first(5),
        'authorized_projects_refresh.rows_added_slice': add.first(5).map(&:values),
        **@duration_statistics
      )
    end

    def current_monotonic_time
      ::Gitlab::Metrics::System.monotonic_time
    end

    def reset_timer_and_store_duration(operation_name)
      duration_key = :"#{operation_name}_duration_s"
      duration_value = (current_monotonic_time - @start_time).round(Gitlab::InstrumentationHelper::DURATION_PRECISION)

      @duration_statistics[duration_key] = duration_value

      @start_time = current_monotonic_time
    end
  end
end
