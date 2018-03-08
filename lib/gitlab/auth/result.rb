module Gitlab # rubocop:disable Naming/FileName
  module Auth
    Result = Struct.new(:actor, :project, :type, :authentication_abilities) do
      prepend ::EE::Gitlab::Auth::Result

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
    end
  end
end
