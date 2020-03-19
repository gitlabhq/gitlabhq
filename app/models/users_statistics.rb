# frozen_string_literal: true

class UsersStatistics < ApplicationRecord
  STATISTICS_NAMES = [
    :without_groups_and_projects,
    :with_highest_role_guest,
    :with_highest_role_reporter,
    :with_highest_role_developer,
    :with_highest_role_maintainer,
    :with_highest_role_owner,
    :bots,
    :blocked
  ].freeze

  private

  def highest_role_stats
    return unless Feature.enabled?(:users_statistics)

    {
      owner: batch_count_for_access_level(Gitlab::Access::OWNER),
      maintainer: batch_count_for_access_level(Gitlab::Access::MAINTAINER),
      developer: batch_count_for_access_level(Gitlab::Access::DEVELOPER),
      reporter: batch_count_for_access_level(Gitlab::Access::REPORTER),
      guest: batch_count_for_access_level(Gitlab::Access::GUEST)
    }
  end

  def batch_count_for_access_level(access_level)
    Gitlab::Database::BatchCount.batch_count(UserHighestRole.with_highest_access_level(access_level))
  end
end
