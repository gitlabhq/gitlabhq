module EE
  module API
    module Helpers
      def current_user
        user = super

        ::Gitlab::Database::LoadBalancing::RackMiddleware.
          stick_or_unstick(env, :user, user.id) if user

        user
      end
    end
  end
end
