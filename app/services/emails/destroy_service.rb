module Emails
  class DestroyService < BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_manage_emails?

      Email.find_by_email(@email).destroy
    end
  end
end
