require 'spec_helper'

describe 'Admin > Users > Impersonation Tokens', feature: true, js: true do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  def active_personal_access_tokens
    find(".table.active-impersonation-tokens")
  end

  def inactive_personal_access_tokens
    find(".table.inactive-impersonation-tokens")
  end

  def created_personal_access_token
    find("#created-impersonation-token").value
  end

  def disallow_personal_access_token_saves!
    allow_any_instance_of(PersonalAccessToken).to receive(:save).and_return(false)
    errors = ActiveModel::Errors.new(PersonalAccessToken.new).tap { |e| e.add(:name, "cannot be nil") }
    allow_any_instance_of(PersonalAccessToken).to receive(:errors).and_return(errors)
  end

  before { login_as(admin) }

  describe "token creation" do
    it "allows creation of a token" do
      name = FFaker::Product.brand

      visit admin_user_impersonation_tokens_path(user_id: user.username)
      fill_in "Name", with: name

      # Set date to 1st of next month
      find_field("Expires at").trigger('focus')
      find(".pika-next").click
      click_on "1"

      # Scopes
      check "api"
      check "read_user"

      expect { click_on "Create Impersonation Token" }.to change { PersonalAccessToken.impersonation.count }
      expect(active_personal_access_tokens).to have_text(name)
      expect(active_personal_access_tokens).to have_text('In')
      expect(active_personal_access_tokens).to have_text('api')
      expect(active_personal_access_tokens).to have_text('read_user')
    end
  end

  describe "inactive tokens" do
    let!(:personal_access_token) { create(:impersonation_personal_access_token, user: user) }

    it "allows revocation of an active impersonation token" do
      visit admin_user_impersonation_tokens_path(user_id: user.username)

      click_on "Revoke"

      expect(inactive_personal_access_tokens).to have_text(personal_access_token.name)
    end

    it "moves expired tokens to the 'inactive' section" do
      personal_access_token.update(expires_at: 5.days.ago)

      visit admin_user_impersonation_tokens_path(user_id: user.username)

      expect(inactive_personal_access_tokens).to have_text(personal_access_token.name)
    end

    context "when revocation fails" do
      before { disallow_personal_access_token_saves! }

      it "displays an error message" do
        visit admin_user_impersonation_tokens_path(user_id: user.username)

        click_on "Revoke"

        expect(active_personal_access_tokens).to have_text(personal_access_token.name)
        expect(page).to have_content("Could not revoke")
      end
    end
  end
end
