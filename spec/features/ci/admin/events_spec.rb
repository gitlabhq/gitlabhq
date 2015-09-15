require 'spec_helper'

describe "Admin Events" do
  let(:event) { FactoryGirl.create :ci_admin_event }
  
  before do
    skip_ci_admin_auth
    login_as :user
  end

  describe "GET /admin/events" do
    before do
      event
      visit ci_admin_events_path
    end

    it { expect(page).to have_content "Events" }
    it { expect(page).to have_content event.description }
  end
end
