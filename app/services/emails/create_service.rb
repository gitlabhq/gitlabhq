module Emails
  class CreateService < ::Emails::BaseService
    def execute(extra_params = {})
      @user.emails.create(@params.merge(extra_params))
    end
  end
end
