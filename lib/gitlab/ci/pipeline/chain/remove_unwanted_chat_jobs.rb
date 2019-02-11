# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class RemoveUnwantedChatJobs < Chain::Base
          def perform!
            # to be overriden in EE
          end

          def break?
            false
          end
        end
      end
    end
  end
end
