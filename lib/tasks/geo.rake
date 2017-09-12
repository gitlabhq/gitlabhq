task spec: ['geo:db:test:prepare']

namespace :geo do
  namespace :db do |ns|
    %i(drop create setup migrate rollback seed version reset).each do |task_name|
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

    namespace :migrate do
      %i(up down redo).each do |task_name|
        task task_name do
          Rake::Task["db:migrate:#{task_name}"].invoke
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

        # Reenable the tasks, otherwise the following tasks are run only once
        # per invocation of `rake`!
        Rake::Task['geo:config:check'].reenable
        Rake::Task['geo:config:set'].reenable
        Rake::Task['geo:config:restore'].reenable
      end
    end

    desc 'Display database encryption key'
    task show_encryption_key: :environment do
      puts Rails.application.secrets.db_key_base
    end
  end

  namespace :config do
    task :check do
      unless File.exist?(Rails.root.join('config/database_geo.yml'))
        abort('You should run these tasks only when GitLab Geo is enabled.')
      end
    end

    task :set do
      # save current configuration
      @previous_config = {
        config: Rails.application.config.dup,
        schema: ENV['SCHEMA']
      }

      # set config variables for geo database
      ENV['SCHEMA'] = 'db/geo/schema.rb'
      Rails.application.config.paths['db'] = ['db/geo']
      Rails.application.config.paths['db/migrate'] = ['db/geo/migrate']
      Rails.application.config.paths['db/seeds.rb'] = ['db/geo/seeds.rb']
      Rails.application.config.paths['config/database'] = ['config/database_geo.yml']
    end

    task :restore do
      # restore config variables to previous values
      ENV['SCHEMA'] = @previous_config[:schema]
      Rails.application.config = @previous_config[:config]
    end
  end

  desc 'Make this node the Geo primary'
  task set_primary_node: :environment do
    abort 'GitLab Geo is not supported with this license. Please contact sales@gitlab.com.' unless Gitlab::Geo.license_allows?
    abort 'GitLab Geo primary node already present' if Gitlab::Geo.primary_node.present?

    set_primary_geo_node
  end

  def set_primary_geo_node
    params = {
      schema: Gitlab.config.gitlab.protocol,
      host: Gitlab.config.gitlab.host,
      port: Gitlab.config.gitlab.port,
      relative_url_root: Gitlab.config.gitlab.relative_url_root,
      primary: true
    }

    node = GeoNode.new(params)
    puts "Saving primary GeoNode with URL #{node.url}".color(:green)
    node.save

    puts "Error saving GeoNode:\n#{node.errors.full_messages.join("\n")}".color(:red) unless node.persisted?
  end
end
