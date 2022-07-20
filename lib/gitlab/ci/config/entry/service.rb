# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker service.
        #
        # TODO: remove duplication with Image superclass by defining a common
        # Imageable concern.
        # https://gitlab.com/gitlab-org/gitlab/issues/208774
        class Service < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[name entrypoint command alias ports variables pull_policy].freeze
          LEGACY_ALLOWED_KEYS = %i[name entrypoint command alias ports variables].freeze

          validations do
            validates :config, hash_or_string: true
            validates :config, allowed_keys: ALLOWED_KEYS, if: :ci_docker_image_pull_policy_enabled?
            validates :config, allowed_keys: LEGACY_ALLOWED_KEYS, unless: :ci_docker_image_pull_policy_enabled?
            validates :config, disallowed_keys: %i[ports], unless: :with_image_ports?
            validates :name, type: String, presence: true
            validates :entrypoint, array_of_strings: true, allow_nil: true

            validates :command, array_of_strings: true, allow_nil: true
            validates :alias, type: String, allow_nil: true
            validates :alias, type: String, presence: true, unless: ->(record) { record.ports.blank? }
          end

          entry :ports, Entry::Ports,
            description: 'Ports used to expose the service'

          entry :pull_policy, Entry::PullPolicy,
            description: 'Pull policy for the service'

          entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
            description: 'Environment variables available for this service.',
            inherit: false

          attributes :ports, :pull_policy, :variables

          def alias
            value[:alias]
          end

          def command
            value[:command]
          end

          def name
            value[:name]
          end

          def entrypoint
            value[:entrypoint]
          end

          def value
            if string?
              { name: @config }
            elsif hash?
              @config.merge(
                pull_policy: (pull_policy_value if ci_docker_image_pull_policy_enabled?)
              ).compact
            else
              {}
            end
          end

          def with_image_ports?
            opt(:with_image_ports)
          end

          def ci_docker_image_pull_policy_enabled?
            ::Feature.enabled?(:ci_docker_image_pull_policy)
          end

          def skip_config_hash_validation?
            true
          end
        end
      end
    end
  end
end
