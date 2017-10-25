namespace :gitlab do
  desc "GitLab | Seed GitLab and create a backup"
  task export_seed: :environment do
    # abort "Do not run outside of CI" unless Rails.env.test?

    # Rake::Task["db:reset"].invoke
    # Rake::Task["setup_postgresql"].invoke
    # Rake::Task["db:seed_fu"].invoke

    #TODO: Seed more data with generate series

    backup_config = if ENV['BACKUP_CONFIG']
      YAML.load(ENV['BACKUP_CONFIG'])
    else
      {}
    end

    Rake::Task["gitlab:backup:create"].invoke(backup_config)

    #TODO: Upload version sha to S3
  end
end
