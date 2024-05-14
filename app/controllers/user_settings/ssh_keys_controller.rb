# frozen_string_literal: true

module UserSettings
  class SshKeysController < ApplicationController
    feature_category :user_profile
    urgency :low, [:create, :index]

    def index
      @keys = current_user.keys.order_id_desc
      @key = Key.new
    end

    def show
      @key = current_user.keys.find(params[:id])
    end

    def create
      @key = Keys::CreateService.new(current_user, key_params.merge(ip_address: request.remote_ip)).execute

      if @key.persisted?
        redirect_to user_settings_ssh_key_path(@key)
      else
        @keys = current_user.keys.select(&:persisted?)
        render :index
      end
    end

    def destroy
      @key = current_user.keys.find(params[:id])
      Keys::DestroyService.new(current_user).execute(@key)

      respond_to do |format|
        format.html { redirect_to user_settings_ssh_keys_url, status: :found }
        format.js { head :ok }
      end
    end

    def revoke
      @key = current_user.keys.find(params[:id])
      Keys::RevokeService.new(current_user).execute(@key)

      respond_to do |format|
        format.html { redirect_to user_settings_ssh_keys_url, status: :found }
        format.js { head :ok }
      end
    end

    private

    def key_params
      params.require(:key).permit(:title, :key, :usage_type, :expires_at)
    end
  end
end
