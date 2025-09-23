# frozen_string_literal: true

module Experimental
  class O11yServiceSettingsController < ApplicationController
    include Gitlab::Utils::StrongMemoize

    before_action :authenticate_user!
    before_action :authorize_experimental_access!

    feature_category :observability
    urgency :low

    def index
      @o11y_service_settings = Observability::GroupO11ySetting.page(pagination_params[:page])
    end

    def new
      @o11y_service_settings = Observability::GroupO11ySetting.new
    end

    def create
      group = Group.find_by_id(o11y_service_settings_params[:group_id])
      if group.nil?
        flash[:alert] = s_('Observability|Group not found')
        @o11y_service_settings = Observability::GroupO11ySetting.new(o11y_service_settings_params)
        render :new, status: :unprocessable_entity
        return
      end

      o11y_service_settings = group.observability_group_o11y_setting
      if o11y_service_settings.present?
        flash[:alert] = s_('Observability|O11y service settings already exist')
        @o11y_service_settings = Observability::GroupO11ySetting.new(o11y_service_settings_params)
        render :new, status: :unprocessable_entity
        return
      end

      @o11y_service_settings = group.build_observability_group_o11y_setting
      result = ::Observability::GroupO11ySettingsUpdateService.new.execute(@o11y_service_settings,
        o11y_service_settings_params)

      if result.success?
        flash[:success] = format(
          s_('Observability|Observability settings for group ID %{group_id} created successfully.'),
          group_id: group.id
        )
        redirect_to new_experimental_o11y_service_setting_url
      else
        flash[:alert] = s_('Observability|Failed to create O11y service settings')
        render :new, status: :unprocessable_entity
      end
    end

    private

    def authorize_experimental_access!
      render_404 unless ::Feature.enabled?(:experimental_group_o11y_settings_access, current_user)
    end

    def o11y_service_settings_params
      params.require(:observability_group_o11y_setting).permit(:group_id, :o11y_service_name, :o11y_service_user_email,
        :o11y_service_password, :o11y_service_post_message_encryption_key)
    end
  end
end
