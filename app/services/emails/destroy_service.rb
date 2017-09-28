module Emails
  class DestroyService < ::Emails::BaseService
    def execute
      update_secondary_emails! if Email.find_by_email!(@email).destroy
    end

    private

    def update_secondary_emails!
      result = ::Users::UpdateService.new(@current_user, user: @user).execute do |user|
        user.update_secondary_emails!
      end

      result[:status] == 'success'
    end
  end
end
