require 'spec_helper'

describe 'Profile > Personal Access Tokens', :js do
  let(:user) { create(:user) }

  def active_personal_access_tokens
    find(".table.active-tokens")
  end

  def no_personal_access_tokens_message
    find(".settings-message")
  end

  def created_personal_access_token
    find("#created-personal-access-token").value
  end

  def disallow_personal_access_token_saves!
    allow_any_instance_of(PersonalAccessToken).to receive(:save).and_return(false)

    errors = ActiveModel::Errors.new(PersonalAccessToken.new).tap { |e| e.add(:name, "cannot be nil") }
    allow_any_instance_of(PersonalAccessToken).to receive(:errors).and_return(errors)
  end

  before do
    sign_in(user)
  end

  describe "token creation" do
    it "allows creation of a personal access token" do
      name = 'My PAT'

      visit profile_personal_access_tokens_path
      fill_in "Name", with: name

      # Set date to 1st of next month
      find_field("Expires at").click
      find(".pika-next").click
      click_on "1"

      # Scopes
      check "api"
      check "read_user"

      click_on "Create personal access token"
      expect(active_personal_access_tokens).to have_text(name)
      expect(active_personal_access_tokens).to have_text('In')
      expect(active_personal_access_tokens).to have_text('api')
      expect(active_personal_access_tokens).to have_text('read_user')
    end

    context "when creation fails" do
      it "displays an error message" do
        disallow_personal_access_token_saves!
        visit profile_personal_access_tokens_path
        fill_in "Name", with: 'My PAT'

        expect { click_on "Create personal access token" }.not_to change { PersonalAccessToken.count }
        expect(page).to have_content("Name cannot be nil")
      end
    end
  end

  describe 'active tokens' do
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let!(:personal_access_token) { create(:personal_access_token, user: user) }

    it 'only shows personal access tokens' do
      visit profile_personal_access_tokens_path

      expect(active_personal_access_tokens).to have_text(personal_access_token.name)
      expect(active_personal_access_tokens).not_to have_text(impersonation_token.name)
    end
  end

  describe "inactive tokens" do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }

    it "allows revocation of an active token" do
      visit profile_personal_access_tokens_path
      accept_confirm { click_on "Revoke" }

      expect(page).to have_selector(".settings-message")
      expect(no_personal_access_tokens_message).to have_text("This user has no active Personal Access Tokens.")
    end

    it "removes expired tokens from 'active' section" do
      personal_access_token.update(expires_at: 5.days.ago)
      visit profile_personal_access_tokens_path

      expect(page).to have_selector(".settings-message")
      expect(no_personal_access_tokens_message).to have_text("This user has no active Personal Access Tokens.")
    end

    context "when revocation fails" do
      it "displays an error message" do
        visit profile_personal_access_tokens_path
        allow_any_instance_of(PersonalAccessToken).to receive(:update!).and_return(false)

        errors = ActiveModel::Errors.new(PersonalAccessToken.new).tap { |e| e.add(:name, "cannot be nil") }
        allow_any_instance_of(PersonalAccessToken).to receive(:errors).and_return(errors)

        accept_confirm { click_on "Revoke" }
        expect(active_personal_access_tokens).to have_text(personal_access_token.name)
        expect(page).to have_content("Could not revoke")
      end
    end
  end
end
