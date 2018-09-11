# frozen_string_literal: true

module Emails
  class CreateService < ::Emails::BaseService
    prepend ::EE::Emails::CreateService

    def execute(extra_params = {})
      skip_confirmation = @params.delete(:skip_confirmation)

      email = @user.emails.create(@params.merge(extra_params))

      email&.confirm if skip_confirmation && current_user.admin?
      email
    end
  end
end
