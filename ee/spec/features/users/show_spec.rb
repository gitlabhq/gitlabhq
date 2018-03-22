require 'spec_helper'

describe 'User page' do
  include ExternalAuthorizationServiceHelpers
  let(:user) { create(:user) }

  it 'shows the most recent activity' do
    visit(user_path(user))

    expect(page).to have_content('Most Recent Activity')
  end

  describe 'when external authorization is enabled' do
    before do
      enable_external_authorization_service_check
    end

    it 'hides the most recent activity' do
      visit(user_path(user))

      expect(page).not_to have_content('Most Recent Activity')
    end
  end
end
