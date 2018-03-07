module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Base
          attr_reader :pipeline, :command

          delegate :project, :current_user, to: :command

          def initialize(pipeline, command)
            @pipeline = pipeline
            @command = command
          end

          def perform!
            raise NotImplementedError
          end

          def break?
            raise NotImplementedError
          end
        end
      end
    end
  end
end
