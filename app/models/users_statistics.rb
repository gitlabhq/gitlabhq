# frozen_string_literal: true

class UsersStatistics < ApplicationRecord
  scope :order_created_at_desc, -> { order(created_at: :desc) }

  class << self
    def latest
      order_created_at_desc.first
    end
  end

  def active
    [
      without_groups_and_projects,
      with_highest_role_guest,
      with_highest_role_reporter,
      with_highest_role_developer,
      with_highest_role_maintainer,
      with_highest_role_owner,
      bots
    ].sum
  end

  def total
    active + blocked
  end

  class << self
    def create_current_stats!
      stats_by_role = highest_role_stats

      create!(
        without_groups_and_projects: without_groups_and_projects_stats,
        with_highest_role_guest: stats_by_role[:guest],
        with_highest_role_reporter: stats_by_role[:reporter],
        with_highest_role_developer: stats_by_role[:developer],
        with_highest_role_maintainer: stats_by_role[:maintainer],
        with_highest_role_owner: stats_by_role[:owner],
        bots: bot_stats,
        blocked: blocked_stats
      )
    end

    private

    def highest_role_stats
      {
        owner: batch_count_for_access_level(Gitlab::Access::OWNER),
        maintainer: batch_count_for_access_level(Gitlab::Access::MAINTAINER),
        developer: batch_count_for_access_level(Gitlab::Access::DEVELOPER),
        reporter: batch_count_for_access_level(Gitlab::Access::REPORTER),
        guest: batch_count_for_access_level(Gitlab::Access::GUEST)
      }
    end

    def without_groups_and_projects_stats
      batch_count_for_access_level(nil)
    end

    def bot_stats
      Gitlab::Database::BatchCount.batch_count(User.bots)
    end

    def blocked_stats
      Gitlab::Database::BatchCount.batch_count(User.blocked)
    end

    def batch_count_for_access_level(access_level)
      Gitlab::Database::BatchCount.batch_count(UserHighestRole.with_highest_access_level(access_level))
    end
  end
end

UsersStatistics.prepend_mod_with('UsersStatistics')
