# frozen_string_literal: true

module Onboarding
  class StatusPresenter
    def self.registration_path_params(params:) # rubocop:disable Lint/UnusedMethodArgument -- overridden in EE
      {}
    end

    def initialize(params, user_return_to, user)
      @params = params
      @user_return_to = user_return_to
      @user = user
    end

    def single_invite?
      # If there are more than one member it will mean we have been invited to multiple projects/groups and
      # are not able to distinguish which one we should putting the user in after registration
      members.size == 1
    end

    def last_invited_member
      members.last
    end

    def last_invited_member_source
      last_invited_member&.source
    end

    # overridden in EE
    def registration_omniauth_params
      {}
    end

    private

    attr_reader :user

    def members
      @members ||= user.members
    end
  end
end

Onboarding::StatusPresenter.prepend_mod
