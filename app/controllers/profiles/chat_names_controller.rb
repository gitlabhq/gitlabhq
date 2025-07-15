# frozen_string_literal: true

class Profiles::ChatNamesController < Profiles::ApplicationController
  include SafeFormatHelper

  before_action :chat_name_token, only: [:new]
  before_action :chat_name_params, only: [:new, :create, :deny]

  feature_category :integrations

  def index
    @chat_names = current_user.chat_names
  end

  def new
    @integration_name = integration_name
  end

  def create
    new_chat_name = current_user.chat_names.new(chat_name_params)

    if new_chat_name.save
      flash[:notice] = safe_format(_("Authorized %{new_chat_name}"), new_chat_name: new_chat_name.chat_name)
    else
      flash[:alert] = s_("Integrations|Could not authorize integration account nickname. Try again!")
    end

    delete_chat_name_token
    redirect_to user_settings_integration_accounts_path
  end

  def deny
    delete_chat_name_token

    flash[:notice] =
      safe_format(_("Denied authorization of account nickname %{user_name}."), user_name: chat_name_params[:user_name])

    redirect_to user_settings_integration_accounts_path
  end

  def destroy
    @chat_name = chat_names.find(params[:id])

    if @chat_name.destroy
      flash[:notice] = safe_format(_("Deleted account nickname: %{chat_name}!"), chat_name: @chat_name.chat_name)
    else
      flash[:alert] = safe_format(_("Could not delete account nickname %{chat_name}."), chat_name: @chat_name.chat_name)
    end

    redirect_to user_settings_integration_accounts_path, status: :found
  end

  private

  def delete_chat_name_token
    chat_name_token.delete
  end

  def chat_name_params
    @chat_name_params ||= chat_name_token.get || render_404
  end

  def chat_name_token
    return render_404 unless params[:token] || render_404

    @chat_name_token ||= Gitlab::ChatNameToken.new(params[:token])
  end

  def chat_names
    @chat_names ||= current_user.chat_names
  end

  def integration_name
    return s_('Integrations|GitLab for Slack app') if slack_app_params?

    s_('Integrations|Mattermost slash commands')
  end

  def slack_app_params?
    chat_name_params[:team_id].start_with?('T') &&
      chat_name_params[:chat_id].start_with?('U', 'W')
  end
end
