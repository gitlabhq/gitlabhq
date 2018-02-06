module EE
  module GroupsHelper
    extend ::Gitlab::Utils::Override

    override :group_nav_link_paths
    def group_nav_link_paths
      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && can?(current_user, :admin_group, @group)
        super + %w[billings#index]
      else
        super
      end
    end
  end
end
