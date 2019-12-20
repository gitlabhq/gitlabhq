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

          ALLOWED_KEYS = %i[before_script image services
                            after_script cache interruptible
                            timeout retry tags artifacts].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          entry :before_script, Entry::Script,
            description: 'Script that will be executed before each job.',
            inherit: true

          entry :image, Entry::Image,
            description: 'Docker image that will be used to execute jobs.',
            inherit: true

          entry :services, Entry::Services,
            description: 'Docker images that will be linked to the container.',
            inherit: true

          entry :after_script, Entry::Script,
            description: 'Script that will be executed after each job.',
            inherit: true

          entry :cache, Entry::Cache,
            description: 'Configure caching between build jobs.',
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

          entry :tags, ::Gitlab::Config::Entry::ArrayOfStrings,
            description: 'Set the default tags.',
            inherit: false

          entry :artifacts, Entry::Artifacts,
            description: 'Default artifacts.',
            inherit: false

          helpers :before_script, :image, :services, :after_script, :cache

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
