# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  admin_user = User.admins.first

  Sidekiq::Worker.skipping_transaction_check do
    Project.not_mass_generated.each do |project|
      params = {
        name: 'master'
      }

      ProtectedBranches::CreateService.new(project, admin_user, params).execute

      # rubocop:disable Rails/Output -- This is a seed file
      print '.'
      # rubocop:enable Rails/Output
    end
  end
end
