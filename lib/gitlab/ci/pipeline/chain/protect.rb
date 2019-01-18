# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Protect < Chain::Base
          def perform!
            @pipeline.protected = @command.protected_ref?
          end

          def break?
            @pipeline.protected? != @command.protected_ref?
          end
        end
      end
    end
  end
end
