require 'spec_helper'

feature 'Project member activity', :js do
  let(:user)            { create(:user) }
  let(:project)         { create(:project, :public, name: 'x', namespace: user.namespace) }

  before do
    project.add_master(user)
  end

  def visit_activities_and_wait_with_event(event_type)
    Event.create(project: project, author_id: user.id, action: event_type)
    visit activity_project_path(project)
    wait_for_requests
  end

  subject { page.find(".event-title").text }

  context 'when a user joins the project' do
    before do
      visit_activities_and_wait_with_event(Event::JOINED)
    end

    it { is_expected.to eq("#{user.name} joined project") }
  end

  context 'when a user leaves the project' do
    before do
      visit_activities_and_wait_with_event(Event::LEFT)
    end

    it { is_expected.to eq("#{user.name} left project") }
  end

  context 'when a users membership expires for the project' do
    before do
      visit_activities_and_wait_with_event(Event::EXPIRED)
    end

    it "presents the correct message" do
      message = "#{user.name} removed due to membership expiration from project"
      is_expected.to eq(message)
    end
  end
end
