module Emails
  class CreateService < ::Emails::BaseService
    def execute
      @user.emails.create(email: @email)
    end
  end
end
