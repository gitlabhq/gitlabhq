# frozen_string_literal: true

module Import
  class SourceUsersController < ApplicationController
    prepend_before_action :check_feature_flag!

    before_action :source_user
    before_action :check_current_user_matches_invite!

    respond_to :html
    feature_category :importers

    def accept
      if source_user.accept
        # TODO: This is where we enqueue the job to assign the contributions.

        redirect_to(root_path, notice: format(mapping_decision_notice('approved'), invite_details))
      else
        redirect_to(root_path, alert: _('The invitation could not be accepted.'))
      end
    end

    def decline
      if source_user.reject
        redirect_to(root_path, notice: format(mapping_decision_notice('rejected'), invite_details))
      else
        redirect_to(root_path, alert: _('The invitation could not be declined.'))
      end
    end

    def show
      redirect_to(root_path, alert: _('The invitation is not valid')) unless source_user.awaiting_approval?
    end

    private

    def check_current_user_matches_invite!
      not_found unless current_user_matches_invite?
    end

    def current_user_matches_invite?
      current_user.id == source_user.reassign_to_user_id
    end

    def source_user
      Import::SourceUser.find(params[:id])
    end
    strong_memoize_attr :source_user

    def invite_details
      {
        source_username: source_user.source_username,
        source_hostname: source_user.source_hostname,
        destination_group: source_user.namespace.name
      }
    end

    def check_feature_flag!
      not_found unless Feature.enabled?(:importer_user_mapping, current_user)
    end

    # TODO: This is a placeholder for the proper UI to be provided
    # in a follow-up MR.
    def mapping_decision_notice(decision)
      "You have #{decision} the reassignment of contributions from " \
        "%{source_username} on %{source_hostname} " \
        "to yourself on %{destination_group}."
    end
  end
end
