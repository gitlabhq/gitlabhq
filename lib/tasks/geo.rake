task spec: ['geo:db:test:prepare']

namespace :geo do
  namespace :db do |ns|
    %i(drop create setup migrate rollback seed version).each do |task_name|
      task task_name do
        Rake::Task["db:#{task_name}"].invoke
      end
    end

    namespace :schema do
      %i(load dump).each do |task_name|
        task task_name do
          Rake::Task["db:schema:#{task_name}"].invoke
        end
      end
    end

    namespace :test do
      task :prepare do
        Rake::Task['db:test:prepare'].invoke
      end
    end

    # append and prepend proper tasks to all the tasks defined above
    ns.tasks.each do |task|
      task.enhance ['geo:config:check', 'geo:config:set'] do
        Rake::Task['geo:config:restore'].invoke
      end
    end
  end

  namespace :config do
    task :check do
      unless File.exist?(Rails.root.join('config/database_geo.yml'))
        abort('You should run these tasks only when GitLab Geo is enabled, and only if it is a secondary node')
      end
    end

    task :set do
      # save current configuration
      @previous_config = {
        config: Rails.application.config.dup,
        schema: ENV['SCHEMA'],
        skip_post_deployment_migrations: ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']
      }

      # set config variables for geo database
      ENV['SCHEMA'] = 'db_geo/schema.rb'
      ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS'] = 'true'
      Rails.application.config.paths['db'] = ['db_geo']
      Rails.application.config.paths['db/migrate'] = ['db_geo/migrate']
      Rails.application.config.paths['db/seeds.rb'] = ['db_geo/seeds.rb']
      Rails.application.config.paths['config/database'] = ['config/database_geo.yml']
    end

    task :restore do
      # restore config variables to previous values
      ENV['SCHEMA'] = @previous_config[:schema]
      ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS'] = @previous_config[:skip_post_deployment_migrations]
      Rails.application.config = @previous_config[:config]
    end
  end
end
