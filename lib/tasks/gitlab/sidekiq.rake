# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :sidekiq do
    namespace :all_queues_yml do
      def write_yaml(path, object)
        banner = <<~BANNER
          # This file is generated automatically by
          #   bin/rake gitlab:sidekiq:all_queues_yml:generate
          #
          # Do not edit it manually!
        BANNER

        File.write(path, banner + YAML.dump(object))
      end

      desc 'GitLab | Generate all_queues.yml based on worker definitions'
      task generate: :environment do
        foss_workers, ee_workers = Gitlab::SidekiqConfig.workers_for_all_queues_yml

        write_yaml(Gitlab::SidekiqConfig::FOSS_QUEUE_CONFIG_PATH, foss_workers)

        if Gitlab.ee?
          write_yaml(Gitlab::SidekiqConfig::EE_QUEUE_CONFIG_PATH, ee_workers)
        end
      end

      desc 'GitLab | Validate that all_queues.yml matches worker definitions'
      task check: :environment do
        if Gitlab::SidekiqConfig.all_queues_yml_outdated?
          raise <<~MSG
            Changes in worker queues found, please update the metadata by running:

              bin/rake gitlab:sidekiq:all_queues_yml:generate

            Then commit and push the changes from:

            - #{Gitlab::SidekiqConfig::FOSS_QUEUE_CONFIG_PATH}
            - #{Gitlab::SidekiqConfig::EE_QUEUE_CONFIG_PATH}

          MSG
        end
      end
    end
  end
end
