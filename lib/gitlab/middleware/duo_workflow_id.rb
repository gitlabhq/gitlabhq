# frozen_string_literal: true

module Gitlab
  module Middleware
    class DuoWorkflowId
      HEADER = 'HTTP_X_GITLAB_DUO_WORKFLOW_ID'
      MAX_VALUE_LENGTH = 255

      def initialize(app)
        @app = app
      end

      def call(env)
        value = env[HEADER].presence

        return @app.call(env) unless value

        Gitlab::ApplicationContext.with_context(duo_workflow_id: value.first(MAX_VALUE_LENGTH)) do
          @app.call(env)
        end
      end
    end
  end
end
