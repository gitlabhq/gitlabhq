namespace :ci do
  desc 'GitLab | Import and migrate CI database'
  task migrate: :environment do
    unless ENV['force'] == 'yes'
      puts "This will truncate all CI tables and restore it from provided backup."
      puts "You will lose any previous CI data stored in the database."
      ask_to_continue
      puts ""
    end

    Rake::Task["ci:migrate:db"].invoke
    Rake::Task["ci:migrate:autoincrements"].invoke
    Rake::Task["ci:migrate:tags"].invoke
    Rake::Task["ci:migrate:services"].invoke
  end

  namespace :migrate do
    desc 'GitLab | Import CI database'
    task db: :environment do
      if ENV["CI_DUMP"].nil?
        puts "No CI SQL dump specified:"
        puts "rake gitlab:backup:restore CI_DUMP=ci_dump.sql"
        exit 1
      end

      ci_dump = ENV["CI_DUMP"]
      unless File.exists?(ci_dump)
        puts "The specified sql dump doesn't exist!"
        exit 1
      end

      ::Ci::Migrate::Database.new.restore(ci_dump)
    end

    desc 'GitLab | Migrate CI tags'
    task tags: :environment do
      ::Ci::Migrate::Tags.new.restore
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
      c = ActiveRecord::Base.connection
      c.execute("UPDATE ci_services SET type=CONCAT('Ci::', type) WHERE type NOT LIKE 'Ci::%'")
    end
  end
end
