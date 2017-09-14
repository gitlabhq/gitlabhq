module Emails
  class CreateService < ::Emails::BaseService
    def execute(options = {})
      @user.emails.create({ email: @email }.merge(options))
    end
  end
end
