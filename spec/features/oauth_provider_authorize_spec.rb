# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Provider', :with_current_organization, feature_category: :system_access do
  let_it_be(:user) { create(:admin, organizations: [current_organization]) }

  def visit_oauth_authorization_path
    visit oauth_authorization_path(
      client_id: application.uid,
      redirect_uri: application.redirect_uri.split.first,
      response_type: 'code',
      state: 'my_state',
      scope: 'read_user'
    )
  end

  def visit_oauth_device_authorization_path
    visit oauth_device_authorizations_index_path(
      user_code: user_code
    )
  end

  before do
    sign_in(user)
  end

  describe 'Standard OAuth Authorization' do
    let(:application) { create(:oauth_application, scopes: 'read_user') }

    before do
      visit_oauth_authorization_path
    end

    it_behaves_like 'Secure OAuth Authorizations'
  end

  describe 'Device OAuth authorization' do
    let(:user_code) { 'valid_user_code' }

    before do
      visit_oauth_device_authorization_path
    end

    it_behaves_like 'Secure Device OAuth Authorizations'
  end

  context 'when the OAuth application has HTML in the name' do
    let_it_be(:client_name) { '<img src=x onerror=alert(1)>' }
    let_it_be(:application) { create(:oauth_application, name: client_name, scopes: 'read_user') }

    before do
      visit_oauth_authorization_path
    end

    it 'sanitizes the HTML in the authorize button' do
      within_testid('authorization-button') do
        expect(page).to have_content(format(_('Authorize %{client_name}'), client_name: client_name))
      end
    end

    it 'expects button not to have an id attribute' do
      expect(find_by_testid('authorization-button')[:id].nil?).to be_truthy
    end

    # rubocop:disable Layout/LineLength -- It is a string
    it 'sanitizes the HTML in the warning text' do
      expect(page).to have_content(
        format(
          _('You are an administrator, which means authorizing access to %{client_name} will allow it to interact with GitLab as an administrator as well.'),
          client_name: client_name
        )
      )
    end
    # rubocop:enable Layout/LineLength

    it 'sanitizes the trust text HTML' do
      expect(page).to have_content(
        format(
          _('Make sure you trust %{client_name} before authorizing.'),
          client_name: client_name
        ))
    end
  end

  context 'when brand title has HTML' do
    let(:application) { create(:oauth_application, scopes: 'read_user') }
    let!(:appearance) { create(:appearance, title: '<img src=x onerror=alert(1)>') }

    before do
      visit_oauth_authorization_path
    end

    it 'sanitizes the HTML' do
      expect(page).to have_content(
        format(_('%{client_name} is requesting access to your account on %{title}.'),
          title: '<img src=x onerror=alert(1)>',
          client_name: application.name
        )
      )
    end
  end
end
