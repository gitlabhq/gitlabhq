# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of job artifacts.
        #
        class Reports < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS =
            %i[junit codequality sast secret_detection dependency_scanning container_scanning
              dast performance browser_performance load_performance license_scanning metrics lsif
              dotenv terraform accessibility
              coverage_fuzzing api_fuzzing cluster_image_scanning
              requirements requirements_v2 coverage_report cyclonedx annotations repository_xray].freeze

          attributes ALLOWED_KEYS

          entry :coverage_report, Reports::CoverageReport, description: 'Coverage report configuration.'

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS

            with_options allow_nil: true do
              validates :junit, array_of_strings_or_string: true
              validates :api_fuzzing, array_of_strings_or_string: true
              validates :coverage_fuzzing, array_of_strings_or_string: true
              validates :sast, array_of_strings_or_string: true
              validates :sast, array_of_strings_or_string: true
              validates :secret_detection, array_of_strings_or_string: true
              validates :dependency_scanning, array_of_strings_or_string: true
              validates :container_scanning, array_of_strings_or_string: true
              validates :cluster_image_scanning, array_of_strings_or_string: true
              validates :dast, array_of_strings_or_string: true
              validates :performance, array_of_strings_or_string: true
              validates :browser_performance, array_of_strings_or_string: true
              validates :load_performance, array_of_strings_or_string: true
              validates :license_scanning, array_of_strings_or_string: true
              validates :metrics, array_of_strings_or_string: true
              validates :lsif, array_of_strings_or_string: true
              validates :dotenv, array_of_strings_or_string: true
              validates :terraform, array_of_strings_or_string: true
              validates :accessibility, array_of_strings_or_string: true
              validates :requirements, array_of_strings_or_string: true
              validates :requirements_v2, array_of_strings_or_string: true
              validates :cyclonedx, array_of_strings_or_string: true
              validates :annotations, array_of_strings_or_string: true
              validates :repository_xray, array_of_strings_or_string: true
            end
          end

          def value
            @config.compact.transform_values do |value|
              if value.is_a?(Hash)
                value
              else
                Array(value)
              end
            end
          end
        end
      end
    end
  end
end
