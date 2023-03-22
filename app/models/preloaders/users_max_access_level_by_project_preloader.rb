# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the users within the given projects and
  # stores the values in requests store via the ProjectTeam class.
  class UsersMaxAccessLevelByProjectPreloader
    include Gitlab::Utils::StrongMemoize

    def initialize(project_users:)
      @project_users = project_users.transform_values { |users| Array.wrap(users) }
    end

    def execute
      return unless @project_users.present?

      all_users = @project_users.values.flatten.uniq
      preload_users_namespace_bans(all_users)

      @project_users.each do |project, users|
        users.each do |user|
          access_level = access_levels.fetch([project.id, user.id], Gitlab::Access::NO_ACCESS)
          project.team.write_member_access_for_user_id(user.id, access_level)
        end
      end
    end

    private

    def access_levels
      query = ProjectAuthorization.none

      @project_users.each do |project, users|
        query = query.or(
          ProjectAuthorization
            .where(project_id: project.id, user_id: users.map(&:id))
        )
      end

      query
        .group(:project_id, :user_id)
        .maximum(:access_level)
    end
    strong_memoize_attr :access_levels

    def preload_users_namespace_bans(_users)
      # overridden in EE
    end
  end
end

Preloaders::UsersMaxAccessLevelByProjectPreloader.prepend_mod
