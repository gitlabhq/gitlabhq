module Teams
  module Users
    class CreateRelationContext < Teams::BaseContext
      def execute
        unless params[:user_ids].blank?
          user_ids = params[:user_ids].split(',')
          access = params[:default_project_access]
          is_admin = params[:group_admin]
          @team.add_members(user_ids, access, is_admin)
        end
      end
    end
  end
end
