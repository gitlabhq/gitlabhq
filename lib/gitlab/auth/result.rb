# frozen_string_literal: true

module Gitlab
  module Auth
    Result = Struct.new(:actor, :project, :type, :authentication_abilities) do
      def ci?(for_project)
        type == :ci &&
          project &&
          project == for_project
      end

      def lfs_deploy_token?(for_project)
        type == :lfs_deploy_token &&
          actor.try(:has_access_to?, for_project)
      end

      def success?
        actor.present? || type == :ci
      end

      def failed?
        !success?
      end

      def auth_user
        actor.is_a?(User) ? actor : nil
      end

      def deploy_token
        actor.is_a?(DeployToken) ? actor : nil
      end
    end
  end
end

Gitlab::Auth::Result.prepend_mod_with('Gitlab::Auth::Result')
