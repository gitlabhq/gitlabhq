module EE
  module API
    module Helpers
      module Runner
        def authenticate_job!
          id = params[:id]

          ::Gitlab::Database::LoadBalancing::RackMiddleware.
            stick_or_unstick(env, :build, id) if id

          super
        end

        def current_runner
          token = params[:token]

          ::Gitlab::Database::LoadBalancing::RackMiddleware.
            stick_or_unstick(env, :runner, token) if token

          super
        end
      end
    end
  end
end
