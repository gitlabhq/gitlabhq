# frozen_string_literal: true

module Admin
  module UserActionsHelper
    def admin_actions(user)
      return [] if user.internal?

      @actions ||= ['edit']

      return @actions if user == current_user

      @user ||= user

      blocked_actions
      deactivate_actions
      unlock_actions
      delete_actions
      ban_actions

      @actions
    end

    private

    def blocked_actions
      if @user.ldap_blocked?
        @actions << 'ldap'
      elsif @user.blocked? && @user.blocked_pending_approval?
        @actions << 'approve'
        @actions << 'reject'
      elsif @user.blocked?
        @actions << 'unblock' unless @user.banned?
      else
        @actions << 'block'
      end
    end

    def deactivate_actions
      if @user.can_be_deactivated?
        @actions << 'deactivate'
      elsif @user.deactivated?
        @actions << 'activate'
      end
    end

    def unlock_actions
      @actions << 'unlock' if @user.access_locked?
    end

    def delete_actions
      return unless can?(current_user, :destroy_user, @user) && !@user.blocked_pending_approval? && @user.can_be_removed?

      @actions << 'delete'
      @actions << 'delete_with_contributions'
    end

    def ban_actions
      return unless ban_feature_available?
      return if @user.internal?

      if @user.banned?
        @actions << 'unban'
        return
      end

      unless @user.blocked?
        @actions << 'ban'
      end
    end
  end
end
