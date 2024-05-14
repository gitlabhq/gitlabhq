# frozen_string_literal: true

namespace :gitlab do
  namespace :user_management do
    desc "GitLab | User management | Update all users of a group with personal project limit to 0 and can_create_group to false"
    task :disable_project_and_group_creation, [:group_id] => :environment do |t, args|
      group = Group.find(args.group_id)
      user_ids = Member.from_union([
        group.hierarchy_members_with_inactive.select(:user_id),
        group.descendant_project_members_with_inactive.select(:user_id)
      ], remove_duplicates: false).distinct.pluck(:user_id)

      result = User.where(id: user_ids).update_all(projects_limit: 0, can_create_group: false)

      if result == user_ids.count
        puts Rainbow("Done").green
      else
        puts Rainbow("Something went wrong").red
      end
    end
  end
end
