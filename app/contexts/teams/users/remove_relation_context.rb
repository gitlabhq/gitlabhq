module Teams
  module Users
    class RemoveRelationContext < Teams::Users::BaseContext
      def execute
        @team.remove_member(@user)
      end
    end
  end
end
