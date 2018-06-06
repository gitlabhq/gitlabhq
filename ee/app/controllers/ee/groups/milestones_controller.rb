module EE
  module Groups
    module MilestonesController
      extend ::Gitlab::Utils::Override

      override :legacy_milestones
      def legacy_milestones
        params[:only_group_milestones] ? [] : super
      end
    end
  end
end
