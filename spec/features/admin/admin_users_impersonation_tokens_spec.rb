# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin > Users > Impersonation Tokens', :js, feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers
  include Features::AccessTokenHelpers

  let(:organization) { create(:organization) }
  let(:admin) { create(:admin, organizations: [organization]) }
  let!(:user) { create(:user, organizations: [organization]) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe "token creation" do
    it "allows creation of a token" do
      name = 'Hello World'

      visit admin_user_impersonation_tokens_path(user_id: user.username)
      click_button 'Add new token'
      fill_in "Token name", with: name

      # Set date to 1st of next month
      find_field("Expiration date").click
      find(".pika-next").click
      click_on "1"

      # Scopes
      check "read_api"
      check "read_user"

      click_on "Create impersonation token"

      expect(active_access_tokens).to have_text(name)
      expect(active_access_tokens).to have_text('in')
      expect(active_access_tokens).to have_text('read_api')
      expect(active_access_tokens).to have_text('read_user')
      expect(PersonalAccessTokensFinder.new(impersonation: true, organization: organization).execute.count).to equal(1)
      expect(created_access_token).to match(/[\w-]{20}/)
    end
  end

  describe 'active tokens' do
    let!(:impersonation_token) do
      create(:personal_access_token, :impersonation, user: user, organization: organization)
    end

    let!(:personal_access_token) { create(:personal_access_token, user: user, organization: organization) }

    it 'only shows impersonation tokens' do
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(active_access_tokens).to have_text(impersonation_token.name)
      expect(active_access_tokens).not_to have_text(personal_access_token.name)
      expect(active_access_tokens).to have_text('in')
    end

    it 'shows absolute times' do
      admin.update!(time_display_relative: false)
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(active_access_tokens).to have_text(personal_access_token.expires_at.strftime('%b %-d'))
    end
  end

  describe "inactive tokens" do
    let!(:impersonation_token) do
      create(:personal_access_token, :impersonation, user: user, organization: organization)
    end

    it "allows revocation of an active impersonation token" do
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      accept_gl_confirm(button_text: 'Revoke') { click_on "Revoke" }

      expect(active_access_tokens).to have_text("This user has no active impersonation tokens.")
    end

    it "removes expired tokens from 'active' section" do
      impersonation_token.update!(expires_at: 5.days.ago)

      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(active_access_tokens).to have_text("This user has no active impersonation tokens.")
    end
  end

  describe "impersonation disabled state" do
    before do
      stub_config_setting(impersonation_enabled: false)
    end

    it "does not show impersonation tokens tab" do
      visit admin_user_path(user)

      expect(page).not_to have_content("Impersonation Tokens")
    end
  end

  describe "rotating tokens" do
    let!(:impersonation_token) do
      create(:personal_access_token, :impersonation, user: user, organization: organization)
    end

    it "displays the newly created token" do
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      accept_gl_confirm(button_text: s_('AccessTokens|Rotate')) { click_on s_('AccessTokens|Rotate') }
      wait_for_all_requests

      expect(page).to have_content("Your new impersonation token has been created.")
      expect(active_access_tokens).to have_text(impersonation_token.name)
      expect(created_access_token).to match(/[\w-]{20}/)
    end

    context "when rotation fails" do
      it "displays an error message" do
        visit admin_user_impersonation_tokens_path(user_id: user.username)

        accept_gl_confirm(button_text: s_('AccessTokens|Rotate')) do
          impersonation_token.revoke!
          click_on s_('AccessTokens|Rotate')
        end
        wait_for_all_requests

        expect(page).to have_content(s_('AccessTokens|Token already revoked'))
      end
    end
  end
end
