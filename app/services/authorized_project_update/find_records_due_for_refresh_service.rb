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

      remove |= current.each_with_object([]) do |(project_id, row), array|
        # rows not in the new list or with a different access level should be
        # removed.
        if !fresh[project_id] || fresh[project_id] != row.access_level
          if incorrect_auth_found_callback
            incorrect_auth_found_callback.call(project_id, row.access_level)
          end

          array << row.project_id
        end
      end

      add = fresh.each_with_object([]) do |(project_id, level), array|
        # rows not in the old list or with a different access level should be
        # added.
        if !current[project_id] || current[project_id].access_level != level
          if missing_auth_found_callback
            missing_auth_found_callback.call(project_id, level)
          end

          array << [user.id, project_id, level]
        end
      end

      [remove, add]
    end

    def needs_refresh?
      remove, add = execute

      remove.present? || add.present?
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
      @current_authorizations ||= user.project_authorizations.select(:project_id, :access_level)
    end

    def fresh_authorizations
      Gitlab::ProjectAuthorizations.new(user).calculate
    end

    private

    attr_reader :user, :source, :incorrect_auth_found_callback, :missing_auth_found_callback

    def projects_with_duplicates
      @projects_with_duplicates ||= current_authorizations
                                      .group_by(&:project_id)
                                      .select { |project_id, authorizations| authorizations.count > 1 }
                                      .keys
    end
  end
end
