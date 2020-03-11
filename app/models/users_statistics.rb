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
end
