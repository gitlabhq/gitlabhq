# frozen_string_literal: true

module AuthorizedProjectUpdate
  # Service for finding the authorized_projects records of a user that needs addition or removal.
  #
  # Usage:
  #
  #     user = User.find_by(username: 'alice')
  #     service = AuthorizedProjectUpdate::FindRecordsDueForRefreshService.new(some_user)
  #     service.execute
  class FindRecordsDueForRefreshService
    def initialize(user, source: nil, incorrect_auth_found_callback: nil, missing_auth_found_callback: nil)
      @user = user
      @source = source
      @incorrect_auth_found_callback = incorrect_auth_found_callback
      @missing_auth_found_callback = missing_auth_found_callback
    end

    def execute
      current = current_authorizations_per_project
      fresh = fresh_access_levels_per_project

      # Projects that have more than one authorizations associated with
      # the user needs to be deleted.
      # The correct authorization is added to the ``add`` array in the
      # next stage.
      remove = projects_with_duplicates
      current.except!(*projects_with_duplicates)

      remove |= current.each_with_object([]) do |(project_id, access_level), array|
        next if fresh[project_id] && fresh[project_id] == access_level

        # rows not in the new list or with a different access level should be
        # removed.

        if incorrect_auth_found_callback
          incorrect_auth_found_callback.call(project_id, access_level)
        end

        array << project_id
      end

      add = fresh.each_with_object([]) do |(project_id, level), array|
        next if current[project_id] && current[project_id] == level

        # rows not in the old list or with a different access level should be
        # added.

        if missing_auth_found_callback
          missing_auth_found_callback.call(project_id, level)
        end

        array << {
          user_id: user.id,
          project_id: project_id,
          access_level: level
        }
      end

      [remove, add]
    end

    def needs_refresh?
      remove, add = execute

      remove.present? || add.present?
    end

    # Both sides of the diff are read as raw [project_id, access_level] pairs
    # rather than ActiveRecord objects. See ProjectAuthorization for why.
    def fresh_access_levels_per_project
      ProjectAuthorization.access_levels_by_project(fresh_authorizations)
    end

    def current_authorizations_per_project
      current_authorizations.to_h
    end

    def current_authorizations
      # Read off the model rather than through `user.project_authorizations`:
      # `pluck` short-circuits to an association's in-memory target when it is
      # already loaded, which would silently return stale rows here.
      @current_authorizations ||= ProjectAuthorization.project_ids_and_access_levels_for(user.id)
    end

    def fresh_authorizations
      Gitlab::ProjectAuthorizations.new(user).calculate
    end

    private

    attr_reader :user, :source, :incorrect_auth_found_callback, :missing_auth_found_callback

    def projects_with_duplicates
      @projects_with_duplicates ||= current_authorizations
                                      .group_by(&:first)
                                      .select { |_project_id, authorizations| authorizations.count > 1 }
                                      .keys
    end
  end
end
