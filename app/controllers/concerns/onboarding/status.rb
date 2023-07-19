# frozen_string_literal: true

module Onboarding
  class Status
    def initialize(user)
      @user = user
    end

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
