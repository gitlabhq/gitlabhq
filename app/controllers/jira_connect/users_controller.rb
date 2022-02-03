# frozen_string_literal: true

class JiraConnect::UsersController < ApplicationController
  feature_category :integrations

  layout 'signup_onboarding'

  before_action :verify_return_to_url, only: [:show]

  def show
    @jira_app_link = params.delete(:return_to)
  end

  private

  def verify_return_to_url
    return unless params[:return_to].present?

    params.delete(:return_to) unless Integrations::Jira.valid_jira_cloud_url?(params[:return_to])
  end
end
