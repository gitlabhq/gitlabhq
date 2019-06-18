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

          DuplicateError = Class.new(Gitlab::Config::Loader::FormatError)

          ALLOWED_KEYS = %i[before_script image services
                            after_script cache].freeze

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

          helpers :before_script, :image, :services, :after_script, :cache

          def compose!(deps = nil)
            super(self)

            inherit!(deps)
          end

          private

          def inherit!(deps)
            return unless deps

            self.class.nodes.each do |key, factory|
              next unless factory.inheritable?

              root_entry = deps[key]
              next unless root_entry.specified?

              if self[key].specified?
                raise DuplicateError, "#{key} is defined in top-level and `default:` entry"
              end

              @entries[key] = root_entry
            end
          end
        end
      end
    end
  end
end
