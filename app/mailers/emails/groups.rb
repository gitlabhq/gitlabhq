module Emails
  module Groups
    def group_access_granted_email(user_group_id)
      @membership = GroupMember.find(user_group_id)
      @group = @membership.group
      @target_url = group_url(@group)
      mail(to: @membership.user.email,
           subject: subject("Access to group was granted"))
    end
  end
end
