# frozen_string_literal: true

module Users
  class TrustService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      UserCustomAttribute.set_trusted_by(user: user, trusted_by: @current_user)
      success
    end
  end
end
