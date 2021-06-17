# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Job < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Processable

          ALLOWED_WHEN = %w[on_success on_failure always manual delayed].freeze
          ALLOWED_KEYS = %i[tags script type image services start_in artifacts
                            cache dependencies before_script after_script
                            environment coverage retry parallel interruptible timeout
                            release dast_configuration secrets].freeze

          REQUIRED_BY_NEEDS = %i[stage].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS + PROCESSABLE_ALLOWED_KEYS
            validates :config, required_keys: REQUIRED_BY_NEEDS, if: :has_needs?
            validates :script, presence: true

            with_options allow_nil: true do
              validates :when, inclusion: {
                in: ALLOWED_WHEN,
                message: "should be one of: #{ALLOWED_WHEN.join(', ')}"
              }

              validates :dependencies, array_of_strings: true
              validates :allow_failure, hash_or_boolean: true
            end

            validates :start_in, duration: { limit: '1 week' }, if: :delayed?
            validates :start_in, absence: true, if: -> { has_rules? || !delayed? }

            validate on: :composed do
              next unless dependencies.present?
              next unless needs_value.present?

              missing_needs = dependencies - needs_value[:job].pluck(:name) # rubocop:disable CodeReuse/ActiveRecord (Array#pluck)

              if missing_needs.any?
                errors.add(:dependencies, "the #{missing_needs.join(", ")} should be part of needs")
              end
            end
          end

          entry :before_script, Entry::Script,
            description: 'Global before script overridden in this job.',
            inherit: true

          entry :script, Entry::Commands,
            description: 'Commands that will be executed in this job.',
            inherit: false

          entry :type, Entry::Stage,
            description: 'Deprecated: stage this job will be executed into.',
            inherit: false

          entry :after_script, Entry::Script,
            description: 'Commands that will be executed when finishing job.',
            inherit: true

          entry :cache, Entry::Caches,
            description: 'Cache definition for this job.',
            inherit: true

          entry :image, Entry::Image,
            description: 'Image that will be used to execute this job.',
            inherit: true

          entry :services, Entry::Services,
            description: 'Services that will be used to execute this job.',
            inherit: true

          entry :interruptible, ::Gitlab::Config::Entry::Boolean,
            description: 'Set jobs interruptible value.',
            inherit: true

          entry :timeout, Entry::Timeout,
            description: 'Timeout duration of this job.',
            inherit: true

          entry :retry, Entry::Retry,
            description: 'Retry configuration for this job.',
            inherit: true

          entry :tags, ::Gitlab::Config::Entry::ArrayOfStrings,
            description: 'Set the tags.',
            inherit: true

          entry :artifacts, Entry::Artifacts,
            description: 'Artifacts configuration for this job.',
            inherit: true

          entry :needs, Entry::Needs,
            description: 'Needs configuration for this job.',
            metadata: { allowed_needs: %i[job cross_dependency] },
            inherit: false

          entry :environment, Entry::Environment,
            description: 'Environment configuration for this job.',
            inherit: false

          entry :coverage, Entry::Coverage,
            description: 'Coverage configuration for this job.',
            inherit: false

          entry :release, Entry::Release,
            description: 'This job will produce a release.',
            inherit: false

          entry :parallel, Entry::Product::Parallel,
            description: 'Parallel configuration for this job.',
            inherit: false

          entry :allow_failure, ::Gitlab::Ci::Config::Entry::AllowFailure,
            description: 'Indicates whether this job is allowed to fail or not.',
            inherit: false

          attributes :script, :tags, :when, :dependencies,
                     :needs, :retry, :parallel, :start_in,
                     :interruptible, :timeout,
                     :release, :allow_failure

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
          end

          def delayed?
            self.when == 'delayed'
          end

          def value
            super.merge(
              before_script: before_script_value,
              script: script_value,
              image: image_value,
              services: services_value,
              cache: cache_value,
              tags: tags_value,
              when: self.when,
              start_in: self.start_in,
              dependencies: dependencies,
              environment: environment_defined? ? environment_value : nil,
              environment_name: environment_defined? ? environment_value[:name] : nil,
              coverage: coverage_defined? ? coverage_value : nil,
              retry: retry_defined? ? retry_value : nil,
              parallel: has_parallel? ? parallel_value : nil,
              interruptible: interruptible_defined? ? interruptible_value : nil,
              timeout: has_timeout? ? ChronicDuration.parse(timeout.to_s) : nil,
              artifacts: artifacts_value,
              release: release_value,
              after_script: after_script_value,
              ignore: ignored?,
              allow_failure_criteria: allow_failure_criteria,
              needs: needs_defined? ? needs_value : nil,
              scheduling_type: needs_defined? ? :dag : :stage
            ).compact
          end

          def ignored?
            allow_failure_defined? ? static_allow_failure : manual_action?
          end

          private

          def allow_failure_criteria
            if allow_failure_defined? && allow_failure_value.is_a?(Hash)
              allow_failure_value
            end
          end

          def static_allow_failure
            return false if allow_failure_value.is_a?(Hash)

            allow_failure_value
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Job.prepend_mod_with('Gitlab::Ci::Config::Entry::Job')
