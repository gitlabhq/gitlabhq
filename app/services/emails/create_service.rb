module Emails
  class CreateService < ::Emails::BaseService
<<<<<<< HEAD
    prepend ::EE::Emails::CreateService

    def execute
      @user.emails.create(email: @email)
=======
    def execute(extra_params = {})
      @user.emails.create(@params.merge(extra_params))
>>>>>>> ce/master
    end
  end
end
