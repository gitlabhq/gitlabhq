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
          ALLOWED_KEYS = %i[tags script image services start_in artifacts
                            cache dependencies before_script after_script hooks
                            coverage retry parallel timeout
                            release id_tokens publish pages manual_confirmation run].freeze

          validations do
            validates :config, allowed_keys: Gitlab::Ci::Config::Entry::Job.allowed_keys + PROCESSABLE_ALLOWED_KEYS
            validates :config, mutually_exclusive_keys: %i[script run]
            validates :script, presence: true, if: -> { config.is_a?(Hash) && !config.key?(:run) }

            with_options allow_nil: true do
              validates :when, type: String, inclusion: {
                in: ALLOWED_WHEN,
                message: "should be one of: #{ALLOWED_WHEN.join(', ')}"
              }

              validates :dependencies, array_of_strings: true
              validates :allow_failure, hash_or_boolean: true
              validates :manual_confirmation, type: String
              validates :run, json_schema: {
                base_directory: 'app/validators/json_schemas',
                detail_errors: true,
                filename: 'run_steps',
                hash_conversion: true
              }
            end

            validates :start_in, duration: { limit: '1 week' }, if: :delayed?
            validates :start_in, absence: true, if: -> { has_rules? || !delayed? }

            validate on: :composed do
              next unless dependencies.present?
              next unless needs_value.present?

              if needs_value[:job].nil? && needs_value[:cross_dependency].present?
                errors.add(:needs, "corresponding to dependencies must be from the same pipeline")
              else
                missing_needs = dependencies - needs_value[:job].pluck(:name) # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck

                errors.add(:dependencies, "the #{missing_needs.join(', ')} should be part of needs") if missing_needs.any?
              end
            end

            validates :publish,
              absence: { message: "can only be used within a `pages` job" },
              unless: -> { config.is_a?(Hash) && pages_job? }
          end

          entry :before_script, Entry::Commands,
            description: 'Global before script overridden in this job.',
            inherit: true

          entry :script, Entry::Commands,
            description: 'Commands that will be executed in this job.',
            inherit: false

          entry :after_script, Entry::Commands,
            description: 'Commands that will be executed when finishing job.',
            inherit: true

          entry :hooks, Entry::Hooks,
            description: 'Commands that will be executed on Runner before/after some events; clone, build-script.',
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

          entry :timeout, Entry::Timeout,
            description: 'Timeout duration of this job.',
            inherit: true

          entry :retry, Entry::Retry,
            description: 'Retry configuration for this job.',
            inherit: true

          entry :tags, Entry::Tags,
            description: 'Set the tags.',
            inherit: true

          entry :artifacts, Entry::Artifacts,
            description: 'Artifacts configuration for this job.',
            inherit: true

          entry :needs, Entry::Needs,
            description: 'Needs configuration for this job.',
            metadata: { allowed_needs: %i[job cross_dependency] },
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

          entry :id_tokens, ::Gitlab::Config::Entry::ComposableHash,
            description: 'Configured JWTs for this job.',
            inherit: true,
            metadata: { composable_class: ::Gitlab::Ci::Config::Entry::IdToken }

          entry :publish, Entry::Publish,
            description: 'Path to be published with Pages',
            inherit: false

          entry :pages, ::Gitlab::Ci::Config::Entry::Pages,
            inherit: false,
            description: 'Pages configuration.'

          attributes :script, :tags, :when, :dependencies,
            :needs, :retry, :parallel, :start_in,
            :timeout, :release,
            :allow_failure, :publish, :pages, :manual_confirmation, :run

          def self.matching?(name, config)
            !name.to_s.start_with?('.') && config.is_a?(Hash) && (config.key?(:script) || config.key?(:run))
          end

          def self.visible?
            true
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
              coverage: coverage_defined? ? coverage_value : nil,
              retry: retry_defined? ? retry_value : nil,
              parallel: has_parallel? ? parallel_value : nil,
              timeout: parsed_timeout,
              artifacts: artifacts_value,
              release: release_value,
              after_script: after_script_value,
              hooks: hooks_value,
              ignore: ignored?,
              allow_failure_criteria: allow_failure_criteria,
              needs: needs_defined? ? needs_value : nil,
              scheduling_type: needs_defined? ? :dag : :stage,
              id_tokens: id_tokens_value,
              publish: publish,
              pages: pages,
              manual_confirmation: self.manual_confirmation,
              run: run
            ).compact
          end

          def parsed_timeout
            return unless has_timeout?

            ChronicDuration.parse(timeout.to_s)
          end

          def ignored?
            allow_failure_defined? ? static_allow_failure : manual_action?
          end

          def pages_job?
            return true if config[:pages].present?

            name == :pages && config[:pages] != false # legacy behavior, overridable with `pages: false`
          end

          def self.allowed_keys
            ALLOWED_KEYS
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
