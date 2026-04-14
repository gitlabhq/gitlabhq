# frozen_string_literal: true

module Groups
  module Observability
    class AccessRequestsController < BaseController
      def new; end

      def create
        if group.observability_group_o11y_setting.present?
          flash[:alert] = s_('Observability|Observability is already enabled for this group')
        else
          result = ::Observability::AccessRequestService.new(
            group,
            current_user
          ).execute

          if result.success?
            flash[:success] = s_('Observability|Welcome to GitLab Observability!')
            redirect_to group_observability_setup_path(group)
            return
          else
            flash[:alert] = result.message
          end
        end

        redirect_to group_observability_setup_path(group)
      end
    end
  end
end
