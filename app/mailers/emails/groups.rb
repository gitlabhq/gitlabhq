module Emails
  module Groups
    def group_access_granted_email(group_member_id)
      @group_member = GroupMember.find(group_member_id)
      @group = @group_member.group

      @target_url = group_url(@group)
      @current_user = @group_member.user

      mail(to: @group_member.user.notification_email,
           subject: subject("Access to group was granted"))
    end

    def group_member_invited_email(group_member_id, token)
      @group_member = GroupMember.find group_member_id
      @group = @group_member.group
      @token = token

      @target_url = group_url(@group)
      @current_user = @group_member.user

      mail(to: @group_member.invite_email,
           subject: "Invitation to join group #{@group.name}")
    end

    def group_invite_accepted_email(group_member_id)
      @group_member = GroupMember.find group_member_id
      return if @group_member.created_by.nil?

      @group = @group_member.group

      @target_url = group_url(@group)
      @current_user = @group_member.created_by

      mail(to: @group_member.created_by.notification_email,
           subject: subject("Invitation accepted"))
    end

    def group_invite_declined_email(group_id, invite_email, access_level, created_by_id)
      return if created_by_id.nil?

      @group = Group.find(group_id)
      @current_user = @created_by = User.find(created_by_id)
      @access_level = access_level
      @invite_email = invite_email
      
      @target_url = group_url(@group)
      mail(to: @created_by.notification_email,
           subject: subject("Invitation declined"))
    end
  end
end
