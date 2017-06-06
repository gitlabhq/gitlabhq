module Gitlab
  module Auth
    class Result
      attr_accessor :actor, :project, :type, :authentication_abilities

      def initialize(actor = nil, project = nil, type = nil, abilities = [])
        @actor = actor
        @project = project
        @type = type
        @authentication_abilities = abilities
      end

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
    end
  end
end
