# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JIRA OAuth Provider', feature_category: :integrations do
  describe 'JIRA DVCS OAuth Authorization' do
    let_it_be(:application) do
      create(:oauth_application, redirect_uri: oauth_jira_dvcs_callback_url, scopes: 'read_user')
    end

    let(:authorize_path) do
      oauth_jira_dvcs_authorize_path(client_id: application.uid,
        redirect_uri: oauth_jira_dvcs_callback_url,
        response_type: 'code',
        state: 'my_state',
        scope: 'read_user')
    end

    before do
      sign_in(user)
    end

    it_behaves_like 'Secure OAuth Authorizations' do
      before do
        visit authorize_path
      end
    end

    context 'when the flag is disabled' do
      let_it_be(:user) { create(:user) }

      before do
        stub_feature_flags(jira_dvcs_end_of_life_amnesty: false)
        visit authorize_path
      end

      it 'presents as an endpoint that does not exist' do
        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
