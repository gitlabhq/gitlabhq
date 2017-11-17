module EE
  module Admin
    module GroupsController
      private

      def allowed_group_params
        super + [
          :repository_size_limit,
          :shared_runners_minutes_limit,
          :plan_id
        ]
      end
    end
  end
end
