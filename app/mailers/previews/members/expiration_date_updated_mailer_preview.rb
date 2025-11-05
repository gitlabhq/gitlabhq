# frozen_string_literal: true

module Members
  class ExpirationDateUpdatedMailerPreview < ActionMailer::Preview
    def email
      Members::ExpirationDateUpdatedMailer.with(member: member, member_source_type: member_source_type).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def member
      GroupMember.last
    end

    def member_source_type
      member.real_source_type
    end
  end
end
