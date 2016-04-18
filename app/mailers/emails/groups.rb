module Emails
  module Groups
    def group_access_requested_email(group_member_id)
      setup_group_member_mail(group_member_id)

      @requester = @group_member.created_by

      group_admins = User.where(id: @group.group_members.admins.pluck(:user_id)).pluck(:notification_email)

      mail(to: group_admins,
           subject: subject("Request to join #{@group.name} group"))
    end

    def group_access_granted_email(group_member_id)
      setup_group_member_mail(group_member_id)

      @current_user = @group_member.user

      mail(to: @current_user.notification_email,
           subject: subject("Access to #{@group.name} group was granted"))
    end

    def group_access_denied_email(group_id, user_id)
      @group = Group.find(group_id)
      @current_user = User.find(user_id)
      @target_url = group_url(@group)

      mail(to: @current_user.notification_email,
           subject: subject("Access to #{@group.name} group was denied"))
    end

    def group_member_invited_email(group_member_id, token)
      setup_group_member_mail(group_member_id)

      @token = token
      @current_user = @group_member.user

      mail(to: @group_member.invite_email,
           subject: "Invitation to join group #{@group.name}")
    end

    def group_invite_accepted_email(group_member_id)
      setup_group_member_mail(group_member_id)
      return if @group_member.created_by.nil?

      @current_user = @group_member.created_by

      mail(to: @current_user.notification_email,
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

    private

    def setup_group_member_mail(group_member_id)
      @group_member = GroupMember.find(group_member_id)
      @group = @group_member.group
      @target_url = group_url(@group)
    end
  end
end
