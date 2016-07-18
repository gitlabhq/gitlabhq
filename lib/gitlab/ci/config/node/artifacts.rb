module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a configuration of job artifacts.
        #
        class Artifacts < Entry
          include Validatable
          include Attributable

          attributes :name, :untracked, :paths, :when, :expire_in

          validations do
            validates :config, type: Hash
            validates :config,
              allowed_keys: %i[name untracked paths when expire_in]

            with_options allow_nil: true do
              validates :name, type: String
              validates :untracked, boolean: true
              validates :paths, array_of_strings: true
              validates :when,
                inclusion: { in: %w[on_success on_failure always],
                             message: 'should be on_success, on_failure ' \
                                      'or always' }
              validates :expire_in, duration: true
            end
          end
        end
      end
    end
  end
end
