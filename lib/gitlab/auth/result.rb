module Gitlab
  module Auth
    class Result < Struct.new(:actor, :project, :type, :authentication_abilities)
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
