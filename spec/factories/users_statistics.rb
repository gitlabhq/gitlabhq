# frozen_string_literal: true

FactoryBot.define do
  factory :users_statistics do
    without_groups_and_projects { 23 }
    with_highest_role_guest { 5 }
    with_highest_role_planner { 7 }
    with_highest_role_reporter { 9 }
    with_highest_role_developer { 21 }
    with_highest_role_maintainer { 6 }
    with_highest_role_owner { 5 }
    bots { 2 }
    blocked { 7 }
  end
end
