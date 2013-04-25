ActiveRecord::Base.observers.disable :all

Gitlab::Seeder.quiet do
  Project.all.each do |project|
    project.team << [User.first, :master]
    print '.'

    User.all.sample(rand(10)).each do |user|
      role = [:master, :developer, :reporter].sample
      project.team << [user, role]
      print '.'
    end
  end
end
