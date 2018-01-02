module EE
  module Ci
    module API
      module Helpers
        def authenticate_build!
          id = params[:id]

          if id
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :build, id)
          end

          super
        end

        def current_runner
          token = params[:token]

          if token
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :runner, token)
          end

          super
        end
      end
    end
  end
end
