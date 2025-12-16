# frozen_string_literal: true

module Members
  class AccessGrantedMailerPreview < ActionMailer::Preview
    def email
      Members::AccessGrantedMailer.with(member: member, member_source_type: member_source_type).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    def project_member_email
      Members::AccessGrantedMailer.with(member: project_member, member_source_type: project_member.real_source_type).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def member
      GroupMember.non_invite.non_request.connected_to_user.last
    end

    def project_member
      ProjectMember.non_invite.non_request.connected_to_user.last
    end

    def member_source_type
      member.real_source_type
    end
  end
end
