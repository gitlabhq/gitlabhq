# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an only/except trigger policy for the job.
        #
        class OnlyPolicy < Policy
          def self.default
            { refs: %w[branches tags] }
          end
        end
      end
    end
  end
end
