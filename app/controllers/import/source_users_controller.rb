# frozen_string_literal: true

module Import
  class SourceUsersController < ApplicationController
    prepend_before_action :check_feature_flag!

    before_action :source_user
    before_action :check_current_user_matches_invite!
    before_action :check_source_user_status!

    respond_to :html
    feature_category :importers

    def accept
      result = ::Import::SourceUsers::AcceptReassignmentService.new(source_user, current_user: current_user).execute

      if result.status == :success
        flash[:raw] = banner('accept_invite')
        redirect_to(dashboard_groups_path)
      else
        redirect_to(dashboard_groups_path, alert: s_('UserMapping|The invitation could not be accepted.'))
      end
    end

    def decline
      if source_user.reject
        flash[:raw] = banner('reject_invite')
        redirect_to(dashboard_groups_path)
      else
        redirect_to(dashboard_groups_path, alert: s_('UserMapping|The invitation could not be declined.'))
      end
    end

    def show; end

    private

    def check_source_user_status!
      return if source_user.awaiting_approval?

      redirect_to(dashboard_groups_path, alert: s_('UserMapping|The invitation is no longer valid.'))
    end

    def check_current_user_matches_invite!
      return if current_user_matches_invite?

      flash[:raw] = banner('cancel_invite')
      redirect_to(dashboard_groups_path)
    end

    def current_user_matches_invite?
      current_user.id == source_user.reassign_to_user_id
    end

    def source_user
      Import::SourceUser.find(params[:id])
    end
    strong_memoize_attr :source_user

    def check_feature_flag!
      not_found unless Feature.enabled?(:importer_user_mapping, current_user)
    end

    def banner(partial)
      render_to_string(
        partial: partial,
        layout: false,
        formats: :html,
        locals: {
          source_user: source_user
        }
      ).html_safe # rubocop: disable Rails/OutputSafety -- render_to_string already makes the string safe
    end
  end
end
