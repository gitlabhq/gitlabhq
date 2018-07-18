# frozen_string_literal: true

module Emails
  class CreateService < ::Emails::BaseService
    prepend ::EE::Emails::CreateService

    def execute(extra_params = {})
      @user.emails.create(@params.merge(extra_params))
    end
  end
end
