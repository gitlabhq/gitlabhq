namespace :gitlab do
  namespace :import do
    # How to use:
    #
    #  1. copy the bare repos under the repository storage paths (commonly the default path is /home/git/repositories)
    #  2. run: bundle exec rake gitlab:import:repos RAILS_ENV=production
    #
    # Notes:
    #  * The project owner will set to the first administator of the system
    #  * Existing projects will be skipped
    #
    #
    desc "GitLab | Import bare repositories from repositories -> storages into GitLab project instance"
    task repos: :environment do
      if Project.current_application_settings.hashed_storage_enabled
        puts 'Cannot import repositories when Hashed Storage is enabled'.color(:red)

        exit 1
      end

      Gitlab::BareRepositoryImporter.execute
    end
  end
end
