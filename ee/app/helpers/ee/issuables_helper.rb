module EE
  module IssuablesHelper
    extend ::Gitlab::Utils::Override

    override :issuable_sidebar_options
    def issuable_sidebar_options(issuable, can_edit_issuable)
      super.merge(
        weightOptions: ::Issue.weight_options,
        weightNoneValue: ::Issue::WEIGHT_NONE
      )
    end

    override :issuable_initial_data
    def issuable_initial_data(issuable)
      data = super.merge(
        canAdmin: can?(current_user, :"admin_#{issuable.to_ability_name}", issuable)
      )

      if parent.is_a?(Group)
        data[:issueLinksEndpoint] = group_epic_issues_path(parent, issuable)
      end

      data
    end
  end
end
