module Emails
  module Members
    extend ActiveSupport::Concern

    included do
      attr_reader :member_target_type
      helper_method :member, :access_requester, :member_target_type, :member_target_name, :member_target_url
    end

    def member_access_requested_email(member_target_type, member_id)
      @member_target_type = member_target_type
      @member_id = member_id

      admins = User.where(id: target.public_send(members_association).admins.pluck(:user_id)).pluck(:notification_email)

      mail(to: admins,
           subject: subject("Request to join the #{member_target_name} #{member_target_type}"))
    end

    def member_access_granted_email(member_target_type, member_id)
      @member_target_type = member_target_type
      @member_id = member_id

      mail(to: member.user.notification_email,
           subject: subject("Access to the #{member_target_name} #{member_target_type} was granted"))
    end

    def member_access_denied_email(member_target_type, target_id, user_id)
      @member_target_type = member_target_type
      @target = target_class.find(target_id)

      mail(to: User.find(user_id).notification_email,
           subject: subject("Access to the #{member_target_name} #{member_target_type} was denied"))
    end

    def member_invited_email(member_target_type, member_id, token)
      @member_target_type = member_target_type
      @member_id = member_id
      @token = token

      mail(to: member.invite_email,
           subject: "Invitation to join the #{member_target_name} #{member_target_type}")
    end

    def member_invite_accepted_email(member_target_type, member_id)
      @member_target_type = member_target_type
      @member_id = member_id
      return if access_requester.nil?

      mail(to: access_requester.notification_email,
           subject: subject('Invitation accepted'))
    end

    def member_invite_declined_email(member_target_type, target_id, invite_email, created_by_id)
      return if created_by_id.nil?

      @member_target_type = member_target_type
      @target = target_class.find(target_id)
      @invite_email = invite_email

      mail(to: User.find(created_by_id).notification_email,
           subject: subject('Invitation declined'))
    end

    def member
      @member ||= member_class.find(@member_id)
    end

    def access_requester
      @access_requester ||= member.created_by
    end

    def member_target_name
      case member_target_type
      when 'project'
        target.name_with_namespace
      else
        target.name
      end
    end

    def member_target_url
      @member_target_url ||= target.web_url
    end

    private

    def target
      @target ||= member.public_send(member_target_type)
    end

    def target_class
      @target_class ||= member_target_type.classify.constantize
    end

    def member_class
      @member_class ||= "#{member_target_type.classify}Member".constantize
    end

    def members_association
      @members_association ||= member_class.to_s.tableize
    end
  end
end
