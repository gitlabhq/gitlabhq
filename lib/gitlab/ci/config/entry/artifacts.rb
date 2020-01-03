# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of job artifacts.
        #
        class Artifacts < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[name untracked paths reports when expire_in expose_as].freeze
          EXPOSE_AS_REGEX = /\A\w[-\w ]*\z/.freeze
          EXPOSE_AS_ERROR_MESSAGE = "can contain only letters, digits, '-', '_' and spaces"

          attributes ALLOWED_KEYS

          entry :reports, Entry::Reports, description: 'Report-type artifacts.'

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :paths, presence: true, if: :expose_as_present?

            with_options allow_nil: true do
              validates :name, type: String
              validates :untracked, boolean: true
              validates :paths, array_of_strings: true
              validates :paths, array_of_strings: {
                with: /\A[^*]*\z/,
                message: "can't contain '*' when used with 'expose_as'"
              }, if: :expose_as_present?
              validates :expose_as, type: String, length: { maximum: 100 }, if: :expose_as_present?
              validates :expose_as, format: { with: EXPOSE_AS_REGEX, message: EXPOSE_AS_ERROR_MESSAGE }, if: :expose_as_present?
              validates :reports, type: Hash
              validates :when,
                inclusion: { in: %w[on_success on_failure always],
                             message: 'should be on_success, on_failure ' \
                                      'or always' }
              validates :expire_in, duration: true
            end
          end

          helpers :reports

          def value
            @config[:reports] = reports_value if @config.key?(:reports)
            @config
          end

          def expose_as_present?
            return false unless Feature.enabled?(:ci_expose_arbitrary_artifacts_in_mr, default_enabled: true)

            # This duplicates the `validates :config, type: Hash` above,
            # but Validatable currently doesn't halt the validation
            # chain if it encounters a validation error.
            return false unless @config.is_a?(Hash)

            !@config[:expose_as].nil?
          end
        end
      end
    end
  end
end
