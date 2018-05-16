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

    def render_sidebar_epic(issuable)
      if issuable.project.feature_available?(:epics)
        render 'shared/issuable/sidebar_item_epic', issuable: issuable
      else
        render 'shared/promotions/promote_epics'
      end
    end
  end
end
