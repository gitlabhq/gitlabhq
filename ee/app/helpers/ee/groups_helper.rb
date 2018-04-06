module EE
  module GroupsHelper
    extend ::Gitlab::Utils::Override

    override :group_nav_link_paths
    def group_nav_link_paths
      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && can?(current_user, :admin_group, @group)
        super + %w[billings#index saml_providers#show]
      else
        super
      end
    end

    private

    def get_group_sidebar_links
      links = super

      if can?(current_user, :read_cross_project)
        if @group.feature_available?(:contribution_analytics) || show_promotions?
          links << :contribution_analytics
        end

        if @group.feature_available?(:group_issue_boards)
          links << :boards
        end

        if @group.feature_available?(:epics)
          links << :epics
        end
      end

      links
    end
  end
end
