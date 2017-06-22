module Emails
  class DestroyService < ::Emails::BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_manage_emails?

      Email.find_by_email(@email).destroy && update_secondary_emails!
    end

    private

    def update_secondary_emails!
      result = ::Users::UpdateService.new(@current_user, @current_user).execute do |user|
        user.update_secondary_emails!
      end

      result[:status] == 'success'
    end
  end
end
