# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JIRA OAuth Provider' do
  describe 'JIRA DVCS OAuth Authorization' do
    let(:application) { create(:oauth_application, redirect_uri: oauth_jira_callback_url, scopes: 'read_user') }

    before do
      sign_in(user)

      visit oauth_jira_authorize_path(client_id: application.uid,
                                      redirect_uri: oauth_jira_callback_url,
                                      response_type: 'code',
                                      state: 'my_state',
                                      scope: 'read_user')
    end

    it_behaves_like 'Secure OAuth Authorizations'
  end
end
