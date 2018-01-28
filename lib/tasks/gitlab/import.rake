namespace :gitlab do
  namespace :import do
    # How to use:
    #
    #  1. copy the bare repos to a specific path that contain the group or subgroups structure as folders
    #  2. run: bundle exec rake gitlab:import:repos[/path/to/repos] RAILS_ENV=production
    #
    # Notes:
    #  * The project owner will set to the first administator of the system
    #  * Existing projects will be skipped
    desc "GitLab | Import bare repositories from repositories -> storages into GitLab project instance"
    task :repos, [:import_path] => :environment do |_t, args|
      unless args.import_path
        puts 'Please specify an import path that contains the repositories'.color(:red)

        exit 1
      end

      Gitlab::BareRepositoryImport::Importer.execute(args.import_path)
    end
  end
end
