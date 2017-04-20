require 'spec_helper'

describe 'Admin > Users > Impersonation Tokens', feature: true, js: true do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  def active_impersonation_tokens
    find(".table.active-tokens")
  end

  def inactive_impersonation_tokens
    find(".table.inactive-tokens")
  end

  before { login_as(admin) }

  describe "token creation" do
    it "allows creation of a token" do
      name = 'Hello World'

      visit admin_user_impersonation_tokens_path(user_id: user.username)
      fill_in "Name", with: name

      # Set date to 1st of next month
      find_field("Expires at").trigger('focus')
      find(".pika-next").click
      click_on "1"

      # Scopes
      check "api"
      check "read_user"

      expect { click_on "Create impersonation token" }.to change { PersonalAccessTokensFinder.new(impersonation: true).execute.count }
      expect(active_impersonation_tokens).to have_text(name)
      expect(active_impersonation_tokens).to have_text('In')
      expect(active_impersonation_tokens).to have_text('api')
      expect(active_impersonation_tokens).to have_text('read_user')
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

      click_on "Revoke"

      expect(inactive_impersonation_tokens).to have_text(impersonation_token.name)
    end

    it "moves expired tokens to the 'inactive' section" do
      impersonation_token.update(expires_at: 5.days.ago)

      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(inactive_impersonation_tokens).to have_text(impersonation_token.name)
    end
  end
end
