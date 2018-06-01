module Gitlab
  module Auth
    module GroupSaml
      class FailureHandler
        def initialize(parent)
          @parent = parent
        end

        def call(env)
          if env['omniauth.error.strategy'].is_a?(OmniAuth::Strategies::GroupSaml)
            ::Groups::OmniauthCallbacksController.action(:failure).call(env)
          else
            @parent.call(env)
          end
        end
      end
    end
  end
end
