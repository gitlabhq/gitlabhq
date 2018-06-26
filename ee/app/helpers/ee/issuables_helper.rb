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

    def group_dropdown_label(group_id, default_label)
      return default_label if group_id.nil?
      return "Any group" if group_id == "0"

      group = ::Group.find_by(id: group_id)

      if group
        group.full_name
      else
        default_label
      end
    end
  end
end
