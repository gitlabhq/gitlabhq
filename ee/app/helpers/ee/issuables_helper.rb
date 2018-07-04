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
  end
end
