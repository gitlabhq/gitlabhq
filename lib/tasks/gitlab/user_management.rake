namespace :gitlab do
  namespace :user_management do
    desc "GitLab | User management | Update all users of a group with personal project limit to 0 and can_create_group to false"
    task :disable_project_and_group_creation, [:group_id] => :environment do |t, args|
      group = Group.find(args.group_id)

      result = User.where(id: group.direct_and_indirect_users_with_inactive.select(:id)).update_all(projects_limit: 0, can_create_group: false)
      ids_count = group.direct_and_indirect_users_with_inactive.count
      puts "Done".color(:green) if result == ids_count
      puts "Something went wrong".color(:red) if result != ids_count
    end
  end
end
