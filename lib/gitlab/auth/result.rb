module Gitlab
  module Auth
    Result = Struct.new(:actor, :project, :type, :authentication_abilities) do
      def ci?
        type == :ci
      end

      def lfs_deploy_token?
        type == :lfs_deploy_token
      end

      def success?
        actor.present? || type == :ci
      end
    end
  end
end
