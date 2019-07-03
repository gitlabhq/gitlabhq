require './spec/support/sidekiq'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    User.all.sample(10).each do |user|
      source_project = Project.public_only.sample

      ##
      # 04_project.rb might not have created a public project because
      # we use randomized approach (e.g. `Array#sample`).
      return unless source_project

      fork_project = Projects::ForkService.new(source_project, user, namespace: user.namespace).execute

      if fork_project.valid?
        print '.'
      else
        print 'F'
      end
    end
  end
end
