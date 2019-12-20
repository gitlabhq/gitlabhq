require './spec/support/sidekiq_middleware'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    User.not_mass_generated.sample(10).each do |user|
      source_project = Project.not_mass_generated.public_only.sample

      ##
      # 03_project.rb might not have created a public project because
      # we use randomized approach (e.g. `Array#sample`).
      return unless source_project

      fork_project = Projects::ForkService.new(
        source_project,
        user,
        namespace: user.namespace,
        skip_disk_validation: true
      ).execute

      if fork_project.valid?
        print '.'
      else
        print 'F'
      end
    end
  end
end
