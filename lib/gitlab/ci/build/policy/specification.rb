module Gitlab
  module Ci
    module Build
      module Policy
        ##
        # Abstract class that defines an intereface of job policy
        # specification.
        #
        # Used for job's only/except policy configuration.
        #
        class Specification
          UnknownPolicyError = Class.new(StandardError)

          def initialize(spec)
            @spec = spec
          end

          def satisfied_by?(pipeline, **metadata)
            raise NotImplementedError
          end

          def self.fabricate_all(*specs)
          end
        end
      end
    end
  end
end
