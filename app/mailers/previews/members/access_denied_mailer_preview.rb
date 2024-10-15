# frozen_string_literal: true

module Members
  class AccessDeniedMailerPreview < ActionMailer::Preview
    def public_source_email
      Members::AccessDeniedMailer.with(member: public_member).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    def private_source_email
      Members::AccessDeniedMailer.with(member: private_member).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def public_member
      # may need to create one if this doesn't find any
      member(Group.public_only)
    end

    def private_member
      # may need to create one if this doesn't find any
      member(Group.private_only)
    end

    def member(scope)
      scope.with_request_group_members.last.request_group_members.last
    end
  end
end
