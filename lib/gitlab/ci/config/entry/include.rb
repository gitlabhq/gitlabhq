# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a single include.
        #
        class Include < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[local file remote template component artifact inputs job project ref rules].freeze

          validations do
            validates :config, hash_or_string: true
            validates :config, allowed_keys: ALLOWED_KEYS

            validate do
              next unless config.is_a?(Hash)

              if config[:artifact] && config[:job].blank?
                errors.add(:config, "must specify the job where to fetch the artifact from")
              end

              if config[:project] && config[:file].blank?
                errors.add(:config, "must specify the file where to fetch the config from")
              end
            end

            with_options allow_nil: true do
              validates :rules, array_of_hashes: true
            end
          end

          entry :rules, ::Gitlab::Ci::Config::Entry::Include::Rules,
            description: 'List of evaluable Rules to determine file inclusion.',
            inherit: false

          attributes :rules

          def skip_config_hash_validation?
            true
          end
        end
      end
    end
  end
end
