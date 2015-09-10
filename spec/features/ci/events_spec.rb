require 'spec_helper'

describe "Events" do
  let(:project) { FactoryGirl.create :project }
  let(:event) { FactoryGirl.create :admin_event, project: project }
  
  before do
    login_as :user
  end

  describe "GET /project/:id/events" do
    before do
      event
      visit project_events_path(project)
    end

    it { expect(page).to have_content "Events" }
    it { expect(page).to have_content event.description }
  end
end
