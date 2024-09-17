# frozen_string_literal: true

module Gitlab
  module Middleware
    class ActionControllerStaticContext
      def initialize(app)
        @app = app
      end

      def call(env)
        req = ActionDispatch::Request.new(env)

        action_name = req.path_parameters[:action]
        caller_id = req.controller_class.try(:endpoint_id_for_action, action_name)
        feature_category = req.controller_class.try(:feature_category_for_action, action_name).to_s
        context = {}
        context[:caller_id] = caller_id if caller_id
        context[:feature_category] = feature_category if feature_category.present?
        # We need to push the context here, so it persists after this middleware finishes
        # We need the values present in Labkit's rack middleware that surrounds this one.
        Gitlab::ApplicationContext.push(context)

        @app.call(env)
      end
    end
  end
end
