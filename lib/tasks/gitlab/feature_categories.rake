# frozen_string_literal: true

namespace :gitlab do
  namespace :feature_categories do
    desc 'GitLab | Feature categories | Build index page for groups'
    task index: :environment do
      require 'pathname'

      controller_actions = Gitlab::RequestEndpoints
                             .all_controller_actions
                             .each_with_object({}) do |(controller, action), hash|
        feature_category = controller.feature_category_for_action(action).to_s

        hash[feature_category] ||= []
        hash[feature_category] << {
          klass: controller.to_s,
          action: action,
          source_location: src_location(controller, action)
        }
      end

      endpoints = Gitlab::RequestEndpoints.all_api_endpoints.each_with_object({}) do |route, hash|
        klass = route.app.options[:for]
        path = API::Base.path_for_app(route.app)
        feature_category = klass.feature_category_for_action(path).to_s

        hash[feature_category] ||= []
        hash[feature_category] << {
          klass: klass.to_s,
          action: path,
          source_location: src_location(klass)
        }
      end

      workers = Gitlab::SidekiqConfig.workers_for_all_queues_yml.flatten.each_with_object({}) do |worker, hash|
        feature_category = worker.get_feature_category.to_s

        next unless worker.klass.name

        hash[feature_category] ||= []
        hash[feature_category] << {
          klass: worker.klass.name,
          source_location: src_location(worker.klass.name)
        }
      end

      database_tables = Dir['db/docs/*.yml'].each_with_object({}) do |file, hash|
        yaml = YAML.safe_load(File.read(file))
        table_name = yaml['table_name']

        yaml['feature_categories'].each do |feature_category|
          hash[feature_category] ||= []
          hash[feature_category] << table_name
        end
      end

      puts YAML.dump('controller_actions' => controller_actions,
        'api_endpoints' => endpoints,
        'sidekiq_workers' => workers,
        'database_tables' => database_tables)
    end

    private

    # Source location of the trace
    # @param [Class] klass
    # @param [Method,UnboundMethod] method
    # @note This method was named `source_location` but this name shadowed Binding#source_location
    # @note This method was made private as it is not being used elsewhere
    def src_location(klass, method = nil)
      file, line =
        if method && klass.method_defined?(method)
          klass.instance_method(method).source_location
        else
          Kernel.const_source_location(klass.to_s)
        end

      relative = Pathname.new(file).relative_path_from(Rails.root).to_s

      if relative.starts_with?('../') || relative.starts_with?('/')
        nil
      else
        [relative, line]
      end
    end
  end
end
