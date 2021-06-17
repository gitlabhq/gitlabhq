# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin > Users > Impersonation Tokens', :js do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  def active_impersonation_tokens
    find(".table.active-tokens")
  end

  def no_personal_access_tokens_message
    find(".settings-message")
  end

  def created_impersonation_token
    find("#created-personal-access-token").value
  end

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe "token creation" do
    it "allows creation of a token" do
      name = 'Hello World'

      visit admin_user_impersonation_tokens_path(user_id: user.username)
      fill_in "Token name", with: name

      # Set date to 1st of next month
      find_field("Expiration date").click
      find(".pika-next").click
      click_on "1"

      # Scopes
      check "api"
      check "read_user"

      click_on "Create impersonation token"

      expect(active_impersonation_tokens).to have_text(name)
      expect(active_impersonation_tokens).to have_text('In')
      expect(active_impersonation_tokens).to have_text('api')
      expect(active_impersonation_tokens).to have_text('read_user')
      expect(PersonalAccessTokensFinder.new(impersonation: true).execute.count).to equal(1)
      expect(created_impersonation_token).not_to be_empty
    end
  end

  describe 'active tokens' do
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let!(:personal_access_token) { create(:personal_access_token, user: user) }

    it 'only shows impersonation tokens' do
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(active_impersonation_tokens).to have_text(impersonation_token.name)
      expect(active_impersonation_tokens).not_to have_text(personal_access_token.name)
    end
  end

  describe "inactive tokens" do
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it "allows revocation of an active impersonation token" do
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      accept_confirm { click_on "Revoke" }

      expect(page).to have_selector(".settings-message")
      expect(no_personal_access_tokens_message).to have_text("This user has no active impersonation tokens.")
    end

    it "removes expired tokens from 'active' section" do
      impersonation_token.update!(expires_at: 5.days.ago)

      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(page).to have_selector(".settings-message")
      expect(no_personal_access_tokens_message).to have_text("This user has no active impersonation tokens.")
    end
  end
end
