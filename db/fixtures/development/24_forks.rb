require './spec/support/sidekiq_middleware'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    User.human.not_mass_generated.sample(10).each do |user|
      source_project = Project.not_mass_generated.public_only.sample

      ##
      # 03_project.rb might not have created a public project because
      # we use randomized approach (e.g. `Array#sample`).
      next unless source_project

      Sidekiq::Worker.skipping_transaction_check do
        response = Projects::ForkService.new(
          source_project,
          user,
          namespace: user.namespace,
          skip_disk_validation: true
        ).execute

        if response.error?
          print 'F'
          next
        end

        fork_project = response[:project]

        # Seed-Fu runs this entire fixture in a transaction, so the `after_commit`
        # hook won't run until after the fixture is loaded. That is too late
        # since the Sidekiq::Testing block has already exited. Force clearing
        # the `after_commit` queue to ensure the job is run now.

        Gitlab::ExclusiveLease.skipping_transaction_check do
          fork_project.send(:_run_after_commit_queue)
          fork_project.import_state.send(:_run_after_commit_queue)
        end
        # We should also force-run the project authorizations refresh job for the created project.
        AuthorizedProjectUpdate::ProjectRecalculateService.new(fork_project).execute

        # Expire repository cache after import to ensure
        # valid_repo? call below returns a correct answer
        fork_project.repository.expire_all_method_caches

        if fork_project.valid? && fork_project.valid_repo?
          print '.'
        else
          print 'F'
        end
      end
    end
  end
end
