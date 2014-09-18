Gitlab::Seeder.quiet do
  Group.all.each do |group|
    User.all.sample(4).each do |user|
      if group.add_users([user.id], Gitlab::Access.values.sample)
        print '.'
      else
        print 'F'
      end
    end
  end

  Project.all.each do |project|
    User.all.sample(4).each do |user|
      if project.team << [user, Gitlab::Access.values.sample]
        print '.'
      else
        print 'F'
      end
    end
  end
end
