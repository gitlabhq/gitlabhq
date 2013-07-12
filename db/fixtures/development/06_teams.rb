ActiveRecord::Base.observers.disable :all

Gitlab::Seeder.quiet do
  Group.all.each do |group|
    User.all.sample(4).each do |user|
      if group.add_users([user.id], UsersGroup.group_access_roles.values.sample)
        print '.'
      else
        print 'F'
      end
    end
  end

  Project.all.each do |project|
    User.all.sample(4).each do |user|
      if project.team << [user, UsersProject.access_roles.values.sample]
        print '.'
      else
        print 'F'
      end
    end
  end
end
