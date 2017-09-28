module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Base
          attr_reader :pipeline, :project, :current_user

          def initialize(pipeline, command)
            @pipeline = pipeline
            @command = command

            @project = command.project
            @current_user = command.current_user
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
