require 'spec_helper'

describe 'Profile > Personal Access Tokens', feature: true, js: true do
  let(:user) { create(:user) }

  def active_personal_access_tokens
    find(".table.active-personal-access-tokens")
  end

  def inactive_personal_access_tokens
    find(".table.inactive-personal-access-tokens")
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
    login_as(user)
  end

  describe "token creation" do
    it "allows creation of a token" do
      visit profile_personal_access_tokens_path
      fill_in "Name", with: FFaker::Product.brand

      expect {click_on "Create Personal Access Token"}.to change { PersonalAccessToken.count }.by(1)
      expect(created_personal_access_token).to eq(PersonalAccessToken.last.token)
      expect(active_personal_access_tokens).to have_text(PersonalAccessToken.last.name)
      expect(active_personal_access_tokens).to have_text("Never")
    end

    it "allows creation of a token with an expiry date" do
      visit profile_personal_access_tokens_path
      fill_in "Name", with: FFaker::Product.brand

      # Set date to 1st of next month
      find_field("Expires at").trigger('focus')
      find("a[title='Next']").click
      click_on "1"

      expect {click_on "Create Personal Access Token"}.to change { PersonalAccessToken.count }.by(1)
      expect(created_personal_access_token).to eq(PersonalAccessToken.last.token)
      expect(active_personal_access_tokens).to have_text(PersonalAccessToken.last.name)
      expect(active_personal_access_tokens).to have_text(Date.today.next_month.at_beginning_of_month.to_s(:medium))
    end

    context "when creation fails" do
      it "displays an error message" do
        disallow_personal_access_token_saves!
        visit profile_personal_access_tokens_path
        fill_in "Name", with: FFaker::Product.brand

        expect { click_on "Create Personal Access Token" }.not_to change { PersonalAccessToken.count }
        expect(page).to have_content("Name cannot be nil")
      end
    end
  end

  describe "inactive tokens" do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }

    it "allows revocation of an active token" do
      visit profile_personal_access_tokens_path
      click_on "Revoke"

      expect(inactive_personal_access_tokens).to have_text(personal_access_token.name)
    end

    it "moves expired tokens to the 'inactive' section" do
      personal_access_token.update(expires_at: 5.days.ago)
      visit profile_personal_access_tokens_path

      expect(inactive_personal_access_tokens).to have_text(personal_access_token.name)
    end

    context "when revocation fails" do
      it "displays an error message" do
        disallow_personal_access_token_saves!
        visit profile_personal_access_tokens_path

        expect { click_on "Revoke" }.not_to change { PersonalAccessToken.inactive.count }
        expect(active_personal_access_tokens).to have_text(personal_access_token.name)
        expect(page).to have_content("Could not revoke")
      end
    end
  end
end
