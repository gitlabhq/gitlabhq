# frozen_string_literal: true

module Groups
  module Settings
    class ApplicationsController < Groups::ApplicationController
      include OauthApplications

      before_action :authorize_admin_group!
      before_action :set_application, only: [:show, :edit, :update, :renew, :destroy]
      before_action :load_scopes, only: [:index, :create, :edit, :update]

      feature_category :system_access

      def index
        set_index_vars
      end

      def show; end

      def edit; end

      def create
        @application = Applications::CreateService.new(current_user, application_params).execute(request)

        if @application.persisted?
          flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

          @created = true
          render :show
        else
          set_index_vars
          render :index
        end
      end

      def update
        if @application.update(application_params)
          redirect_to group_settings_application_path(@group, @application),
            notice: _('Application was successfully updated.')
        else
          render :edit
        end
      end

      def renew
        @application.renew_secret

        if @application.save
          render json: { secret: @application.plaintext_secret }
        else
          render json: { errors: @application.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @application.destroy
        redirect_to group_settings_applications_url(@group), status: :found,
          notice: _('Application was successfully destroyed.')
      end

      private

      def set_index_vars
        @applications = @group.oauth_applications.keyset_paginate(cursor: params[:cursor])
        @applications_total_count = @group.oauth_applications.count

        # Don't overwrite a value possibly set by `create`
        @application ||= Doorkeeper::Application.new
      end

      def set_application
        @application = @group.oauth_applications.find(params[:id])
      end

      def application_params
        super.tap do |params|
          params[:owner] = @group
        end
      end
    end
  end
end
