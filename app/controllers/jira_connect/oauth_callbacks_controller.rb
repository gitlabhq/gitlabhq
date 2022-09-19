# frozen_string_literal: true

# This controller's role is to serve as a landing page
# that users get redirected to after installing and authenticating
# The GitLab.com for Jira App (https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud)
#
class JiraConnect::OauthCallbacksController < ApplicationController
  feature_category :integrations

  skip_before_action :authenticate_user!

  def index; end
end
