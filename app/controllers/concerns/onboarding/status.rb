# frozen_string_literal: true

module Onboarding
  class Status
    def self.tracking_label
      { free: 'free_registration' }
    end

    def initialize(params, session, user)
      @params = params
      @session = session
      @user = user
    end

    # overridden in EE
    def continue_full_onboarding?
      false
    end

    def single_invite?
      # If there are more than one member it will mean we have been invited to multiple projects/groups and
      # are not able to distinguish which one we should putting the user in after registration
      members.count == 1
    end

    def last_invited_member
      members.last
    end

    def last_invited_member_source
      last_invited_member&.source
    end

    def invite_with_tasks_to_be_done?
      return false if members.empty?

      MemberTask.for_members(members).exists?
    end

    private

    attr_reader :user

    def members
      @members ||= user.members
    end
  end
end

Onboarding::Status.prepend_mod_with('Onboarding::Status')
