# frozen_string_literal: true

module Members
  class AboutToExpireMailerPreview < ActionMailer::Preview
    def email
      Members::AboutToExpireMailer.with(member: member).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def member
      project.add_member(user, Gitlab::Access::GUEST, expires_at: 7.days.from_now.to_date)
    end

    def project
      Project.first
    end

    def user
      User.last
    end
  end
end
