require './spec/support/sidekiq_middleware'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    Group.not_mass_generated.each do |group|
      User.not_mass_generated.sample(4).each do |user|
        if group.add_member(user, Gitlab::Access.values.sample).persisted?
          print '.'
        else
          print 'F'
        end
      end
    end

    Project.not_mass_generated.each do |project|
      User.not_mass_generated.sample(4).each do |user|
        if project.add_role(user, Gitlab::Access.sym_options.keys.sample)
          print '.'
        else
          print 'F'
        end
      end
    end
  end
end
