# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Personal Access Tokens', :js do
  let(:user) { create(:user) }
  let(:pat_create_service) { double('PersonalAccessTokens::CreateService', execute: ServiceResponse.error(message: 'error', payload: { personal_access_token: PersonalAccessToken.new })) }

  def active_personal_access_tokens
    find(".table.active-tokens")
  end

  def no_personal_access_tokens_message
    find(".settings-message")
  end

  def created_personal_access_token
    find("#created-personal-access-token").value
  end

  def feed_token
    find("#feed_token").value
  end

  def disallow_personal_access_token_saves!
    allow(PersonalAccessTokens::CreateService).to receive(:new).and_return(pat_create_service)

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
      expect(created_personal_access_token).not_to be_empty
    end

    context "when creation fails" do
      it "displays an error message" do
        disallow_personal_access_token_saves!
        visit profile_personal_access_tokens_path
        fill_in "Name", with: 'My PAT'

        expect { click_on "Create personal access token" }.not_to change { PersonalAccessToken.count }
        expect(page).to have_content("Name cannot be nil")
        expect(page).not_to have_selector("#created-personal-access-token")
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
      expect(no_personal_access_tokens_message).to have_text("This user has no active personal access tokens.")
    end

    it "removes expired tokens from 'active' section" do
      personal_access_token.update!(expires_at: 5.days.ago)
      visit profile_personal_access_tokens_path

      expect(page).to have_selector(".settings-message")
      expect(no_personal_access_tokens_message).to have_text("This user has no active personal access tokens.")
    end

    context "when revocation fails" do
      it "displays an error message" do
        visit profile_personal_access_tokens_path

        allow_next_instance_of(PersonalAccessTokens::RevokeService) do |instance|
          allow(instance).to receive(:revocation_permitted?).and_return(false)
        end

        accept_confirm { click_on "Revoke" }
        expect(active_personal_access_tokens).to have_text(personal_access_token.name)
        expect(page).to have_content("Not permitted to revoke")
      end
    end
  end

  describe "feed token" do
    context "when enabled" do
      it "displays feed token" do
        allow(Gitlab::CurrentSettings).to receive(:disable_feed_token).and_return(false)
        visit profile_personal_access_tokens_path

        expect(page).to have_content("Your feed token is used to authenticate you when your RSS reader loads a personalized RSS feed or when your calendar application loads a personalized calendar, and is included in those feed URLs.")
        expect(feed_token).to eq(user.feed_token)
      end
    end

    context "when disabled" do
      it "does not display feed token" do
        allow(Gitlab::CurrentSettings).to receive(:disable_feed_token).and_return(true)
        visit profile_personal_access_tokens_path

        expect(page).not_to have_content("Your feed token is used to authenticate you when your RSS reader loads a personalized RSS feed or when your calendar application loads a personalized calendar, and is included in those feed URLs.")
        expect(page).not_to have_css("#feed_token")
      end
    end
  end

  it 'pushes `personal_access_tokens_scoped_to_projects` feature flag to the frontend' do
    visit profile_personal_access_tokens_path

    expect(page).to have_pushed_frontend_feature_flags(personalAccessTokensScopedToProjects: true)
  end
end
