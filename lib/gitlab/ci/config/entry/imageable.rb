# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Represents Imageable concern shared by Image and Service.
        module Imageable
          extend ActiveSupport::Concern

          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Configurable

          IMAGEABLE_ALLOWED_KEYS = %i[name entrypoint ports pull_policy].freeze

          included do
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, hash_or_string: true
              validates :config, disallowed_keys: %i[ports], unless: :with_image_ports?

              validates :name, type: String, presence: true
              validates :entrypoint, array_of_strings: true, allow_nil: true
            end

            attributes :ports, :pull_policy

            entry :ports, Entry::Ports,
                description: 'Ports used to expose the image/service'

            entry :pull_policy, Entry::PullPolicy,
                description: 'Pull policy for the image/service'
          end

          def name
            value[:name]
          end

          def entrypoint
            value[:entrypoint]
          end

          def with_image_ports?
            opt(:with_image_ports)
          end

          def skip_config_hash_validation?
            true
          end
        end
      end
    end
  end
end
