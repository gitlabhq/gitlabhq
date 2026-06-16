# frozen_string_literal: true

module Gitlab
  module Middleware
    class DuoWorkflowId
      HEADER = 'HTTP_X_GITLAB_DUO_WORKFLOW_ID'
      STORE_KEY = :duo_workflow_id
      MAX_VALUE_LENGTH = 255

      def initialize(app)
        @app = app
      end

      def call(env)
        value = env[HEADER].presence
        Gitlab::SafeRequestStore[STORE_KEY] = value.first(MAX_VALUE_LENGTH) if value

        @app.call(env)
      end
    end
  end
end
