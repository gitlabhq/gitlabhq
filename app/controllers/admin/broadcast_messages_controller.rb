# frozen_string_literal: true

class Admin::BroadcastMessagesController < Admin::ApplicationController
  include BroadcastMessagesHelper

  before_action :finder, only: [:edit, :update, :destroy]

  feature_category :onboarding
  urgency :low

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @broadcast_messages = BroadcastMessage.order(ends_at: :desc).page(params[:page])
    @broadcast_message  = BroadcastMessage.new
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def edit
  end

  def create
    @broadcast_message = BroadcastMessage.new(broadcast_message_params)

    if @broadcast_message.save
      redirect_to admin_broadcast_messages_path, notice: _('Broadcast Message was successfully created.')
    else
      render :index
    end
  end

  def update
    if @broadcast_message.update(broadcast_message_params)
      redirect_to admin_broadcast_messages_path, notice: _('Broadcast Message was successfully updated.')
    else
      render :edit
    end
  end

  def destroy
    @broadcast_message.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(default: { action: 'index' }) }
      format.js { head :ok }
    end
  end

  def preview
    @broadcast_message = BroadcastMessage.new(broadcast_message_params)
    render partial: 'admin/broadcast_messages/preview'
  end

  protected

  def finder
    @broadcast_message = BroadcastMessage.find(params[:id])
  end

  def broadcast_message_params
    params.require(:broadcast_message).permit(%i(
      theme
      ends_at
      message
      starts_at
      target_path
      broadcast_type
      dismissable
    ), target_access_levels: []).reverse_merge!(target_access_levels: [])
  end
end
