# frozen_string_literal: true

module Groups
  module Observability
    class O11yServiceSettingsController < Groups::ApplicationController
      include Gitlab::Utils::StrongMemoize

      before_action :authenticate_user!
      before_action :authorize_o11y_settings_access!
      before_action :authorize_o11y_destroy_access!, only: :destroy

      feature_category :observability
      urgency :low

      def update
        result = ::Observability::GroupO11ySettingsUpdateService.new.execute(settings, settings_params)
        if result.success?
          redirect_to edit_group_observability_o11y_service_settings_path(@group),
            notice: s_('Observability|Observability service settings updated successfully.')
        else
          flash.now[:alert] = result.message
          render :edit
        end
      end

      def edit
        settings
      end

      def destroy
        if settings.new_record? || settings.destroy
          redirect_to edit_group_observability_o11y_service_settings_path(@group),
            notice: s_('Observability|Observability service settings deleted successfully.'),
            status: :see_other
        else
          redirect_to edit_group_observability_o11y_service_settings_path(@group),
            alert: s_('Observability|Failed to delete observability service settings.'),
            status: :see_other
        end
      rescue ActiveRecord::RecordNotDestroyed
        redirect_to edit_group_observability_o11y_service_settings_path(@group),
          alert: s_('Observability|Failed to delete observability service settings.'),
          status: :see_other
      end

      private

      def authorize_o11y_settings_access!
        return render_404 unless ::Feature.enabled?(:o11y_settings_access, current_user)

        render_404 unless Ability.allowed?(current_user, :update_o11y_settings, group)
      end

      def authorize_o11y_destroy_access!
        render_404 unless Ability.allowed?(current_user, :delete_o11y_settings, group)
      end

      def settings_params
        params.require(:observability_group_o11y_setting).permit(
          :o11y_service_name,
          :o11y_service_user_email,
          :o11y_service_password,
          :o11y_service_post_message_encryption_key
        )
      end

      def settings
        group.observability_group_o11y_setting || group.build_observability_group_o11y_setting
      end
      strong_memoize_attr :settings
    end
  end
end
