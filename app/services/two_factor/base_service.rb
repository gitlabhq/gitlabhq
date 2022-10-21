# frozen_string_literal: true

module TwoFactor
  class BaseService
    include BaseServiceUtility

    attr_reader :current_user, :user, :group

    def initialize(current_user, params = {})
      @current_user = current_user
      @user = params.delete(:user)
      @group = params.delete(:group)
    end
  end
end
