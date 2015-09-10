require 'spec_helper'

describe "Admin Events" do
  let(:event) { FactoryGirl.create :admin_event }
  
  before do
    skip_admin_auth
    login_as :user
  end

  describe "GET /admin/events" do
    before do
      event
      visit admin_events_path
    end

    it { expect(page).to have_content "Events" }
    it { expect(page).to have_content event.description }
  end
end
