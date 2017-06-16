module Emails
  class CreateService < BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_manage_emails?

      @user.emails.create!(email: @email)
    end
  end
end
