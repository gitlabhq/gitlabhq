module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of job artifacts.
        #
        class Artifacts < Node
          include Configurable
          include Validatable
          include Attributable

          ALLOWED_KEYS = %i[name untracked paths reports when expire_in].freeze

          attributes ALLOWED_KEYS

          entry :reports, Entry::Reports, description: 'Report-type artifacts.'

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS

            with_options allow_nil: true do
              validates :name, type: String
              validates :untracked, boolean: true
              validates :paths, array_of_strings: true
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
        end
      end
    end
  end
end
