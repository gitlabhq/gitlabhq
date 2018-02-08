module EE
  module API
    module Helpers
      extend ::Gitlab::Utils::Override

      override :current_user
      def current_user
        strong_memoize(:current_user) do
          user = super

          if user
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :user, user.id)
          end

          user
        end
      end

      def check_project_feature_available!(feature)
        not_found! unless user_project.feature_available?(feature)
      end
    end
  end
end
