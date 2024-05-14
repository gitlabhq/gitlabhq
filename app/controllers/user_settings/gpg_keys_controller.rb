# frozen_string_literal: true

module UserSettings
  class GpgKeysController < ApplicationController
    before_action :set_gpg_key, only: [:destroy, :revoke]

    feature_category :source_code_management

    def index
      @gpg_keys = current_user.gpg_keys.with_subkeys
      @gpg_key = GpgKey.new
    end

    def create
      @gpg_key = GpgKeys::CreateService.new(current_user, gpg_key_params).execute

      if @gpg_key.persisted?
        redirect_to user_settings_gpg_keys_path
      else
        @gpg_keys = current_user.gpg_keys.select(&:persisted?)
        render :index
      end
    end

    def destroy
      GpgKeys::DestroyService.new(current_user).execute(@gpg_key)

      respond_to do |format|
        format.html { redirect_to user_settings_gpg_keys_url, status: :found }
        format.js { head :ok }
      end
    end

    def revoke
      @gpg_key.revoke

      respond_to do |format|
        format.html { redirect_to user_settings_gpg_keys_url, status: :found }
        format.js { head :ok }
      end
    end

    private

    def gpg_key_params
      params.require(:gpg_key).permit(:key)
    end

    def set_gpg_key
      @gpg_key = current_user.gpg_keys.find(params[:id])
    end
  end
end
