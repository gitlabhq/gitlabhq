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
    attr_reader :user

    LEASE_TIMEOUT = 1.minute.to_i

    # user - The User for which to refresh the authorized projects.
    def initialize(user)
      @user = user

      # We need an up to date User object that has access to all relations that
      # may have been created earlier. The only way to ensure this is to reload
      # the User object.
      user.reset
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

      begin
        execute_without_lease
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, uuid)
      end
    end

    # This method returns the updated User object.
    def execute_without_lease
      current = current_authorizations_per_project
      fresh = fresh_access_levels_per_project

      remove = current.each_with_object([]) do |(project_id, row), array|
        # rows not in the new list or with a different access level should be
        # removed.
        if !fresh[project_id] || fresh[project_id] != row.access_level
          array << row.project_id
        end
      end

      add = fresh.each_with_object([]) do |(project_id, level), array|
        # rows not in the old list or with a different access level should be
        # added.
        if !current[project_id] || current[project_id].access_level != level
          array << [user.id, project_id, level]
        end
      end

      update_authorizations(remove, add)
    end

    # Updates the list of authorizations for the current user.
    #
    # remove - The IDs of the authorization rows to remove.
    # add - Rows to insert in the form `[user id, project id, access level]`
    def update_authorizations(remove = [], add = [])
      return if remove.empty? && add.empty?

      User.transaction do
        user.remove_project_authorizations(remove) unless remove.empty?
        ProjectAuthorization.insert_authorizations(add) unless add.empty?
      end

      # Since we batch insert authorization rows, Rails' associations may get
      # out of sync. As such we force a reload of the User object.
      user.reset
    end

    def fresh_access_levels_per_project
      fresh_authorizations.each_with_object({}) do |row, hash|
        hash[row.project_id] = row.access_level
      end
    end

    def current_authorizations_per_project
      current_authorizations.index_by(&:project_id)
    end

    def current_authorizations
      user.project_authorizations.select(:project_id, :access_level)
    end

    def fresh_authorizations
      Gitlab::ProjectAuthorizations.new(user).calculate
    end
  end
end
