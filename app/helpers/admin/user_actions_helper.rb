# frozen_string_literal: true

module Admin
  module UserActionsHelper
    def admin_actions(user)
      return [] if user.internal?

      @user = user
      @actions = []

      organization_admin_area? ? organization_admin_actions : instance_admin_actions

      @actions
    end

    private

    def organization_admin_actions
      []
    end

    def instance_admin_actions
      edit_actions
      return if @user == current_user

      blocked_actions
      deactivate_actions
      unlock_actions
      delete_actions
      ban_actions
      trust_actions
    end

    def organization_admin_area?
      respond_to?(:options) && options[:authorization_context].is_a?(::Organizations::Organization)
    end

    def edit_actions
      @actions << 'edit' if can?(current_user, :admin_all_resources)
    end

    def blocked_actions
      return unless can?(current_user, :admin_all_resources)

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
      return unless can?(current_user, :admin_all_resources)

      if @user.can_be_deactivated?
        @actions << 'deactivate'
      elsif @user.deactivated?
        @actions << 'activate'
      end
    end

    def unlock_actions
      @actions << 'unlock' if @user.access_locked? && can?(current_user, :admin_all_resources)
    end

    def delete_actions
      return unless can?(current_user, :destroy_user, @user) && !@user.blocked_pending_approval?

      @actions << 'delete' if @user.solo_owned_groups.none?
      @actions << 'delete_with_contributions'
    end

    def ban_actions
      return if @user.internal? || !can?(current_user, :admin_all_resources)

      if @user.banned?
        @actions << 'unban'
        return
      end

      @actions << 'ban' unless @user.blocked?
    end

    def trust_actions
      return unless can?(current_user, :admin_all_resources)

      return if @user.internal? ||
        @user.blocked_pending_approval? ||
        @user.banned? ||
        @user.blocked? ||
        @user.deactivated?

      @actions << if @user.trusted?
                    'untrust'
                  else
                    'trust'
                  end
    end
  end
end

::Admin::UserActionsHelper.prepend_mod
