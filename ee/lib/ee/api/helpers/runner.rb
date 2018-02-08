module EE
  module API
    module Helpers
      module Runner
        extend ::Gitlab::Utils::Override

        override :authenticate_job!
        def authenticate_job!
          id = params[:id]

          if id
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :build, id)
          end

          super
        end

        override :current_runner
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
