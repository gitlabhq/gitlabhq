namespace :ci do
  desc 'GitLab | Import and migrate CI database'
  task migrate: :environment do
    warn_user_is_not_gitlab
    configure_cron_mode

    unless ENV['force'] == 'yes'
      puts 'This will remove all CI related data and restore it from the provided backup.'
      ask_to_continue
      puts ''
    end

    # disable CI for time of migration
    enable_ci(false)

    # unpack archives
    migrate = Ci::Migrate::Manager.new
    migrate.unpack

    Rake::Task['ci:migrate:db'].invoke
    Rake::Task['ci:migrate:builds'].invoke
    Rake::Task['ci:migrate:tags'].invoke
    Rake::Task['ci:migrate:services'].invoke

    # enable CI for time of migration
    enable_ci(true)

    migrate.cleanup
  end

  namespace :migrate do
    desc 'GitLab | Import CI database'
    task db: :environment do
      configure_cron_mode
      $progress.puts 'Restoring database ... '.blue
      Ci::Migrate::Database.new.restore
      $progress.puts 'done'.green
    end

    desc 'GitLab | Import CI builds'
    task builds: :environment do
      configure_cron_mode
      $progress.puts 'Restoring builds ... '.blue
      Ci::Migrate::Builds.new.restore
      $progress.puts 'done'.green
    end

    desc 'GitLab | Migrate CI tags'
    task tags: :environment do
      configure_cron_mode
      $progress.puts 'Migrating tags ... '.blue
      ::Ci::Migrate::Tags.new.restore
      $progress.puts 'done'.green
    end

    desc 'GitLab | Migrate CI auto-increments'
    task autoincrements: :environment do
      c = ActiveRecord::Base.connection
      c.tables.select { |t| t.start_with?('ci_') }.each do |table|
        result = c.select_one("SELECT id FROM #{table} ORDER BY id DESC LIMIT 1")
        if result
          ai_val = result['id'].to_i + 1
          puts "Resetting auto increment ID for #{table} to #{ai_val}"
          if c.adapter_name == 'PostgreSQL'
            c.execute("ALTER SEQUENCE #{table}_id_seq RESTART WITH #{ai_val}")
          else
            c.execute("ALTER TABLE #{table} AUTO_INCREMENT = #{ai_val}")
          end
        end
      end
    end

    desc 'GitLab | Migrate CI services'
    task services: :environment do
      $progress.puts 'Migrating services ... '.blue
      c = ActiveRecord::Base.connection
      c.execute("UPDATE ci_services SET type=CONCAT('Ci::', type) WHERE type NOT LIKE 'Ci::%'")
      $progress.puts 'done'.green
    end
  end

  def enable_ci(enabled)
    settings = ApplicationSetting.current || ApplicationSetting.create_from_defaults
    settings.ci_enabled = enabled
    settings.save!
  end
end
