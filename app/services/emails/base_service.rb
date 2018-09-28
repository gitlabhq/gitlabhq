# frozen_string_literal: true

module Emails
  class BaseService
    attr_reader :current_user

    def initialize(current_user, params = {})
      @current_user, @params = current_user, params.dup
      @user = params.delete(:user)
    end
  end
end
