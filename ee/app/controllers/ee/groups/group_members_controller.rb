module EE
  module Groups
    module GroupMembersController
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :admin_not_required_endpoints
        def admin_not_required_endpoints
          super.concat(%i[update override])
        end
      end

      prepended do
        before_action :authorize_update_group_member!, only: [:update, :override]
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def override
        member = @group.members.find_by!(id: params[:id])
        updated_member = ::Members::UpdateService.new(current_user, override_params)
          .execute(member, permission: :override)

        if updated_member.valid?
          respond_to do |format|
            format.js { head :ok }
          end
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      protected

      def authorize_update_group_member!
        unless can?(current_user, :admin_group_member, group) || can?(current_user, :override_group_member, group)
          render_403
        end
      end

      def override_params
        params.require(:group_member).permit(:override)
      end
    end
  end
end
