require './spec/support/sidekiq'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    User.all.sample(10).each do |user|
      source_project = Project.public_only.sample
      fork_project = Projects::ForkService.new(source_project, user, namespace: user.namespace).execute

      if fork_project.valid?
        puts '.'
      else
        puts 'F'
      end
    end
  end
end
