module EE
  module Admin
    module UsersController
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
