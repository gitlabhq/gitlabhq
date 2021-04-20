# frozen_string_literal: true

module TwoFactor
  class BaseService
    include BaseServiceUtility

    attr_reader :current_user, :params, :user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
      @user = params.delete(:user)
    end
  end
end
