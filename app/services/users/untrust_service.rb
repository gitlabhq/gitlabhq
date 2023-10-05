# frozen_string_literal: true

module Users
  class UntrustService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      user.trusted_with_spam_attribute.delete
      success
    end
  end
end
