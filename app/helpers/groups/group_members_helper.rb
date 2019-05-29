# frozen_string_literal: true

module Groups::GroupMembersHelper
  def group_member_select_options
    { multiple: true, class: 'input-clamp', scope: :all, email_user: true }
  end
end
