# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a single include.
        #
        class Include < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseInclude

          # Additional keys beyond the common ones
          ADDITIONAL_ALLOWED_KEYS = %i[template artifact inputs job rules component].freeze
          ALLOWED_KEYS = (COMMON_ALLOWED_KEYS + ADDITIONAL_ALLOWED_KEYS).freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS

            validate do
              next unless config.is_a?(Hash)

              if config[:artifact] && config[:job].blank?
                errors.add(:config, "must specify the job where to fetch the artifact from")
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
        end
      end
    end
  end
end
