# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # This class represents a default entry
        # Entry containing default values for all jobs
        # defined in configuration file.
        #
        class Default < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Inheritable

          ALLOWED_KEYS = %i[before_script after_script hooks cache image services
                            interruptible timeout retry tags artifacts id_tokens].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          entry :before_script, Entry::Commands,
            description: 'Script that will be executed before each job.',
            inherit: true

          entry :after_script, Entry::Commands,
            description: 'Script that will be executed after each job.',
            inherit: true

          entry :hooks, Entry::Hooks,
            description: 'Commands that will be executed on Runner before/after some events ' \
                         'such as `clone` and `build-script`.',
            inherit: false

          entry :cache, Entry::Caches,
            description: 'Configure caching between build jobs.',
            inherit: true

          entry :image, Entry::Image,
            description: 'Docker image that will be used to execute jobs.',
            inherit: true

          entry :services, Entry::Services,
            description: 'Docker images that will be linked to the container.',
            inherit: true

          entry :interruptible, ::Gitlab::Config::Entry::Boolean,
            description: 'Set jobs interruptible default value.',
            inherit: false

          entry :timeout, Entry::Timeout,
            description: 'Set jobs default timeout.',
            inherit: false

          entry :retry, Entry::Retry,
            description: 'Set retry default value.',
            inherit: false

          entry :tags, Entry::Tags,
            description: 'Set the default tags.',
            inherit: false

          entry :artifacts, Entry::Artifacts,
            description: 'Default artifacts.',
            inherit: false

          entry :id_tokens, ::Gitlab::Config::Entry::ComposableHash,
            description: 'Configured JWTs for this job',
            inherit: false,
            metadata: { composable_class: ::Gitlab::Ci::Config::Entry::IdToken }

          private

          def overwrite_entry(deps, key, current_entry)
            inherited_entry = deps[key]

            if inherited_entry.specified? && current_entry.specified?
              raise InheritError, "#{key} is defined in top-level and `default:` entry"
            end

            inherited_entry unless current_entry.specified?
          end
        end
      end
    end
  end
end
