# frozen_string_literal: true

module JiraConnect
  class PublicKeysController < ::ApplicationController
    # This is not inheriting from JiraConnect::Application controller because
    # it doesn't need to handle JWT authentication.

    feature_category :integrations

    skip_before_action :authenticate_user!

    def show
      if Feature.disabled?(:jira_connect_oauth_self_managed) || !Gitlab.config.jira_connect.enable_public_keys_storage
        return render_404
      end

      render plain: public_key.key
    end

    private

    def public_key
      JiraConnect::PublicKey.find(params[:id])
    end
  end
end
