# frozen_string_literal: true

module Users
  class SignupService < BaseService
    def initialize(current_user, params = {})
      @user = current_user
      @params = params.dup
    end

    def execute
      assign_attributes
      inject_validators

      if @user.save
        success
      else
        error(@user.errors.full_messages.join('. '))
      end
    end

    private

    def assign_attributes
      @user.assign_attributes(params) unless params.empty?
    end

    def inject_validators
      class << @user
        validates :role, presence: true
        validates :setup_for_company, inclusion: { in: [true, false], message: :blank }
      end
    end
  end
end
