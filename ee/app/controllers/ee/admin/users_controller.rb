# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module UsersController
      def reset_runners_minutes
        user

        if ClearNamespaceSharedRunnersMinutesService.new(@user.namespace).execute
          redirect_to [:admin, @user], notice: 'User pipeline minutes were successfully reset.'
        else
          flash.now[:error] = 'There was an error resetting user pipeline minutes.'
          render "edit"
        end
      end

      private

      def allowed_user_params
        super + [
          :note,
          namespace_attributes: [:id, :shared_runners_minutes_limit, :plan_id]
        ]
      end
    end
  end
end
