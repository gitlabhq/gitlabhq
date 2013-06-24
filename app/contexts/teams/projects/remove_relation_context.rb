module Teams
  module Projects
    class RemoveRelationContext < Teams::Projects::BaseContext
      def execute
        Gitlab::UserTeamManager.resign(team, project)
      end
    end
  end
end
