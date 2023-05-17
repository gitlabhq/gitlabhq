# frozen_string_literal: true

module JiraConnect
  class PublicKeysController < ::ApplicationController
    # This is not inheriting from JiraConnect::Application controller because
    # it doesn't need to handle JWT authentication.

    feature_category :integrations

    skip_before_action :authenticate_user!

    def show
      return render_404 unless public_key_storage_enabled?

      render plain: public_key.key
    end

    private

    def public_key
      JiraConnect::PublicKey.find(params[:id])
    end

    def public_key_storage_enabled?
      Gitlab::CurrentSettings.jira_connect_public_key_storage_enabled?
    end
  end
end
