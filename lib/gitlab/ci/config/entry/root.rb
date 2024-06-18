# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # This class represents a global entry - root Entry for entire
        # GitLab CI Configuration file.
        #
        class Root < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[default include before_script image services
                            after_script variables stages cache workflow].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          # reserved:
          #   defines whether the node name is reserved
          #   the reserved name cannot be used a job name
          #   reserved should not be used as it will make
          #   breaking change to `.gitlab-ci.yml`

          entry :default, Entry::Default,
            description: 'Default configuration for all jobs.',
            default: {}

          entry :include, Entry::Includes,
            description: 'List of external YAML files to include.',
            reserved: true

          entry :before_script, Entry::Commands,
            description: 'Script that will be executed before each job.',
            reserved: true

          entry :image, Entry::Image,
            description: 'Docker image that will be used to execute jobs.',
            reserved: true

          entry :services, Entry::Services,
            description: 'Docker images that will be linked to the container.',
            reserved: true

          entry :after_script, Entry::Commands,
            description: 'Script that will be executed after each job.',
            reserved: true

          entry :variables, Entry::Variables,
            description: 'Environment variables that will be used.',
            metadata: { allowed_value_data: %i[value description expand options] },
            reserved: true

          entry :stages, Entry::Stages,
            description: 'Configuration of stages for this pipeline.',
            reserved: true

          entry :cache, Entry::Caches,
            description: 'Configure caching between build jobs.',
            reserved: true

          entry :workflow, Entry::Workflow,
            description: 'List of evaluable rules to determine Pipeline status',
            default: {}

          dynamic_helpers :jobs

          delegate :before_script_value,
            :image_value,
            :services_value,
            :after_script_value,
            :cache_value, to: :default_entry

          attr_reader :jobs_config

          class << self
            include ::Gitlab::Utils::StrongMemoize

            def reserved_nodes_names
              strong_memoize(:reserved_nodes_names) do
                self.nodes.select do |_, node|
                  node.reserved?
                end.keys
              end
            end
          end

          def initialize(config, **metadata)
            super do
              filter_jobs!
            end
          end

          def compose!(_deps = nil)
            super(self) do
              compose_jobs!
            end
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def compose_jobs!
            factory = logger.instrument(:config_root_compose_jobs_factory, once: true) do
              ::Gitlab::Config::Entry::Factory.new(Entry::Jobs)
                .value(jobs_config)
                .with(key: :jobs, parent: self,
                  description: 'Jobs definition for this pipeline')
            end

            @entries[:jobs] = logger.instrument(:config_root_compose_jobs_create, once: true) do
              factory.create!
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def filter_jobs!
            return unless @config.is_a?(Hash)

            @jobs_config = @config
              .except(*self.class.reserved_nodes_names)
              .select do |name, config|
              Entry::Jobs.find_type(name, config).present? || ALLOWED_KEYS.exclude?(name)
            end

            @config = @config.except(*@jobs_config.keys)
          end

          def logger
            metadata[:logger]
          end
        end
      end
    end
  end
end
