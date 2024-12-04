# frozen_string_literal: true

class UsersStatistics < ApplicationRecord
  scope :order_created_at_desc, -> { order(created_at: :desc) }

  def active
    [
      without_groups_and_projects,
      with_highest_role_guest,
      with_highest_role_planner,
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
    def latest
      order_created_at_desc.first
    end

    def create_current_stats!
      create!(highest_role_stats)
    end

    private

    def highest_role_stats
      {
        without_groups_and_projects: without_groups_and_projects_stats,
        with_highest_role_guest: batch_count_for_access_level(Gitlab::Access::GUEST),
        with_highest_role_planner: batch_count_for_access_level(Gitlab::Access::PLANNER),
        with_highest_role_reporter: batch_count_for_access_level(Gitlab::Access::REPORTER),
        with_highest_role_developer: batch_count_for_access_level(Gitlab::Access::DEVELOPER),
        with_highest_role_maintainer: batch_count_for_access_level(Gitlab::Access::MAINTAINER),
        with_highest_role_owner: batch_count_for_access_level(Gitlab::Access::OWNER),
        bots: bot_stats,
        blocked: blocked_stats
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
