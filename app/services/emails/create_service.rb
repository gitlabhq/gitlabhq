module Emails
  class CreateService < ::Emails::BaseService
    prepend ::EE::Emails::CreateService

    def execute
      @user.emails.create(email: @email)
    end
  end
end
