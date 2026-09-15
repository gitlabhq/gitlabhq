# frozen_string_literal: true

module Import
  class SourceUsersController < ApplicationController
    before_action :check_source_user_valid!

    respond_to :html
    feature_category :importers

    def accept
      result = ::Import::SourceUsers::AcceptReassignmentService.new(
        source_user, current_user: current_user, reassignment_token: reassignment_token
      ).execute

      if result.success?
        flash[:raw] = banner('accept_invite')
        redirect_to(root_path)
      else
        redirect_to(root_path, alert: s_('UserMapping|The invitation could not be accepted.'))
      end
    end

    def decline
      result = ::Import::SourceUsers::RejectReassignmentService.new(
        source_user, current_user: current_user, reassignment_token: reassignment_token
      ).execute

      if result.success?
        flash[:raw] = banner('reject_invite')
        redirect_to(root_path)
      else
        redirect_to(root_path, alert: s_('UserMapping|The invitation could not be declined.'))
      end
    end

    def show; end

    private

    def check_source_user_valid!
      return if source_user&.awaiting_approval? && current_user_matches_invite?

      flash[:raw] = banner('invalid_invite')
      redirect_to(root_path)
    end

    def current_user_matches_invite?
      current_user.id == source_user.reassign_to_user_id
    end

    def source_user_params
      params.permit(:namespace_id, :reassignment_token)
    end

    def source_user
      namespace_id = source_user_params[:namespace_id]
      if namespace_id.present?
        Import::SourceUser.find_by_namespace_and_token(
          namespace_id: namespace_id,
          reassignment_token: reassignment_token
        )
      else
        Import::SourceUser.find_by_reassignment_token(reassignment_token)
      end
    end
    strong_memoize_attr :source_user

    def reassignment_token
      source_user_params[:reassignment_token]
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
