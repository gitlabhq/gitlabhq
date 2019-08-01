# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Job < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[tags script only except type image services
                            allow_failure type stage when start_in artifacts cache
                            dependencies needs before_script after_script variables
                            environment coverage retry parallel extends].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, presence: true
            validates :script, presence: true
            validates :name, presence: true
            validates :name, type: Symbol

            with_options allow_nil: true do
              validates :tags, array_of_strings: true
              validates :allow_failure, boolean: true
              validates :parallel, numericality: { only_integer: true,
                                                   greater_than_or_equal_to: 2,
                                                   less_than_or_equal_to: 50 }
              validates :when,
                inclusion: { in: %w[on_success on_failure always manual delayed],
                             message: 'should be on_success, on_failure, ' \
                                      'always, manual or delayed' }
              validates :dependencies, array_of_strings: true
              validates :needs, array_of_strings: true
              validates :extends, array_of_strings_or_string: true
            end

            validates :start_in, duration: { limit: '1 day' }, if: :delayed?
            validates :start_in, absence: true, unless: :delayed?

            validate do
              next unless dependencies.present?
              next unless needs.present?

              missing_needs = dependencies - needs
              if missing_needs.any?
                errors.add(:dependencies, "the #{missing_needs.join(", ")} should be part of needs")
              end
            end
          end

          entry :before_script, Entry::Script,
            description: 'Global before script overridden in this job.',
            inherit: true

          entry :script, Entry::Commands,
            description: 'Commands that will be executed in this job.'

          entry :stage, Entry::Stage,
            description: 'Pipeline stage this job will be executed into.'

          entry :type, Entry::Stage,
            description: 'Deprecated: stage this job will be executed into.'

          entry :after_script, Entry::Script,
            description: 'Commands that will be executed when finishing job.',
            inherit: true

          entry :cache, Entry::Cache,
            description: 'Cache definition for this job.',
            inherit: true

          entry :image, Entry::Image,
            description: 'Image that will be used to execute this job.',
            inherit: true

          entry :services, Entry::Services,
            description: 'Services that will be used to execute this job.',
            inherit: true

          entry :only, Entry::Policy,
            description: 'Refs policy this job will be executed for.',
            default: Entry::Policy::DEFAULT_ONLY

          entry :except, Entry::Policy,
            description: 'Refs policy this job will be executed for.'

          entry :variables, Entry::Variables,
            description: 'Environment variables available for this job.'

          entry :artifacts, Entry::Artifacts,
            description: 'Artifacts configuration for this job.'

          entry :environment, Entry::Environment,
            description: 'Environment configuration for this job.'

          entry :coverage, Entry::Coverage,
            description: 'Coverage configuration for this job.'

          entry :retry, Entry::Retry,
               description: 'Retry configuration for this job.'

          helpers :before_script, :script, :stage, :type, :after_script,
                  :cache, :image, :services, :only, :except, :variables,
                  :artifacts, :environment, :coverage, :retry,
                  :parallel, :needs

          attributes :script, :tags, :allow_failure, :when, :dependencies,
                     :needs, :retry, :parallel, :extends, :start_in

          def self.matching?(name, config)
            !name.to_s.start_with?('.') &&
              config.is_a?(Hash) && config.key?(:script)
          end

          def self.visible?
            true
          end

          def compose!(deps = nil)
            super do
              if type_defined? && !stage_defined?
                @entries[:stage] = @entries[:type]
              end

              @entries.delete(:type)
            end

            inherit!(deps)
          end

          def name
            @metadata[:name]
          end

          def value
            @config.merge(to_hash.compact)
          end

          def manual_action?
            self.when == 'manual'
          end

          def delayed?
            self.when == 'delayed'
          end

          def ignored?
            allow_failure.nil? ? manual_action? : allow_failure
          end

          private

          # We inherit config entries from `default:`
          # if the entry has the `inherit: true` flag set
          def inherit!(deps)
            return unless deps

            self.class.nodes.each do |key, factory|
              next unless factory.inheritable?

              default_entry = deps.default[key]
              job_entry = self[key]

              if default_entry.specified? && !job_entry.specified?
                @entries[key] = default_entry
              end
            end
          end

          def to_hash
            { name: name,
              before_script: before_script_value,
              script: script_value,
              image: image_value,
              services: services_value,
              stage: stage_value,
              cache: cache_value,
              only: only_value,
              except: except_value,
              variables: variables_defined? ? variables_value : {},
              environment: environment_defined? ? environment_value : nil,
              environment_name: environment_defined? ? environment_value[:name] : nil,
              coverage: coverage_defined? ? coverage_value : nil,
              retry: retry_defined? ? retry_value : nil,
              parallel: parallel_defined? ? parallel_value.to_i : nil,
              artifacts: artifacts_value,
              after_script: after_script_value,
              ignore: ignored?,
              needs: needs_defined? ? needs_value : nil }
          end
        end
      end
    end
  end
end
