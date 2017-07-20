module EE
  module Groups
    module GroupMembersController
      def override
        @group_member = @group.group_members.find(params[:id])

        return render_403 unless can?(current_user, :override_group_member, @group_member)

        if @group_member.update_attributes(override_params)
          log_audit_event(@group_member, action: :override)

          respond_to do |format|
            format.js { head :ok }
          end
        end
      end

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
