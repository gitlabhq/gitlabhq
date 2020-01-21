# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of job artifacts.
        #
        class Reports < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[junit codequality sast dependency_scanning container_scanning dast performance license_management license_scanning metrics].freeze

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS

            with_options allow_nil: true do
              validates :junit, array_of_strings_or_string: true
              validates :codequality, array_of_strings_or_string: true
              validates :sast, array_of_strings_or_string: true
              validates :dependency_scanning, array_of_strings_or_string: true
              validates :container_scanning, array_of_strings_or_string: true
              validates :dast, array_of_strings_or_string: true
              validates :performance, array_of_strings_or_string: true
              validates :license_management, array_of_strings_or_string: true
              validates :license_scanning, array_of_strings_or_string: true
              validates :metrics, array_of_strings_or_string: true
            end
          end

          def value
            @config.transform_values { |v| Array(v) }
          end
        end
      end
    end
  end
end
