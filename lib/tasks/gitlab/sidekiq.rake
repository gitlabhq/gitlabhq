# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :sidekiq do
    def write_yaml(path, banner, object)
      File.write(path, banner + YAML.dump(object).gsub(/ *$/m, ''))
    end

    namespace :all_queues_yml do
      desc 'GitLab | Sidekiq | Generate all_queues.yml based on worker definitions'
      task generate: :environment do
        banner = <<~BANNER
          # This file is generated automatically by
          #   bin/rake gitlab:sidekiq:all_queues_yml:generate
          #
          # Do not edit it manually!
        BANNER

        foss_workers, ee_workers = Gitlab::SidekiqConfig.workers_for_all_queues_yml

        write_yaml(Gitlab::SidekiqConfig::FOSS_QUEUE_CONFIG_PATH, banner, foss_workers)

        if Gitlab.ee?
          write_yaml(Gitlab::SidekiqConfig::EE_QUEUE_CONFIG_PATH, banner, ee_workers)
        end
      end

      desc 'GitLab | Sidekiq | Validate that all_queues.yml matches worker definitions'
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

    namespace :sidekiq_queues_yml do
      desc 'GitLab | Sidekiq | Generate sidekiq_queues.yml based on worker definitions'
      task generate: :environment do
        banner = <<~BANNER
          # This file is generated automatically by
          #   bin/rake gitlab:sidekiq:sidekiq_queues_yml:generate
          #
          # Do not edit it manually!
          #
          # This configuration file should be exclusively used to set queue settings for
          # Sidekiq. Any other setting should be specified using the Sidekiq CLI or the
          # Sidekiq Ruby API (see config/initializers/sidekiq.rb).
          #
          # All the queues to process and their weights. Every queue _must_ have a weight
          # defined.
          #
          # The available weights are as follows
          #
          # 1: low priority
          # 2: medium priority
          # 3: high priority
          # 5: _super_ high priority, this should only be used for _very_ important queues
          #
          # As per http://stackoverflow.com/a/21241357/290102 the formula for calculating
          # the likelihood of a job being popped off a queue (given all queues have work
          # to perform) is:
          #
          #     chance = (queue weight / total weight of all queues) * 100
        BANNER

        queues_and_weights = Gitlab::SidekiqConfig.queues_for_sidekiq_queues_yml

        write_yaml(Gitlab::SidekiqConfig::SIDEKIQ_QUEUES_PATH, banner, queues: queues_and_weights)
      end

      desc 'GitLab | Sidekiq | Validate that sidekiq_queues.yml matches worker definitions'
      task check: :environment do
        if Gitlab::SidekiqConfig.sidekiq_queues_yml_outdated?
          raise <<~MSG
            Changes in worker queues found, please update the metadata by running:

              bin/rake gitlab:sidekiq:sidekiq_queues_yml:generate

            Then commit and push the changes from:

            - #{Gitlab::SidekiqConfig::SIDEKIQ_QUEUES_PATH}

          MSG
        end
      end
    end
  end
end
