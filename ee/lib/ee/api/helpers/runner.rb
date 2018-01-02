module EE
  module API
    module Helpers
      module Runner
        def authenticate_job!
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
