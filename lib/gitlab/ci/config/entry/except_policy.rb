# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an only/except trigger policy for the job.
        #
        class ExceptPolicy < Policy
          def self.default
          end
        end
      end
    end
  end
end
