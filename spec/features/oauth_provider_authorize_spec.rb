# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Provider' do
  describe 'Standard OAuth Authorization' do
    let(:application) { create(:oauth_application, scopes: 'read_user') }

    before do
      sign_in(user)

      visit oauth_authorization_path(client_id: application.uid,
                                     redirect_uri: application.redirect_uri.split.first,
                                     response_type: 'code',
                                     state: 'my_state',
                                     scope: 'read_user')
    end

    it_behaves_like 'Secure OAuth Authorizations'
  end
end
