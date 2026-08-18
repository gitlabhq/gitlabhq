# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project member activity', :js, feature_category: :user_profile do
  let(:user)            { create(:user) }
  let(:project)         { create(:project, :public, name: 'x', namespace: user.namespace) }

  before do
    project.add_maintainer(user)
  end

  def visit_activities_with_event(event_type)
    Event.create!(project: project, author_id: user.id, action: event_type)
    visit activity_project_path(project)
  end

  context 'when a user joins the project' do
    before do
      visit_activities_with_event(:joined)
    end

    it "presents the correct message" do
      expect(page).to have_selector('.event-user-info', exact_text: "#{user.name} #{user.to_reference}")
      expect(page).to have_selector('.event-title', exact_text: "joined project #{project.full_name}")
    end
  end

  context 'when a user leaves the project' do
    before do
      visit_activities_with_event(:left)
    end

    it "presents the correct message" do
      expect(page).to have_selector('.event-user-info', exact_text: "#{user.name} #{user.to_reference}")
      expect(page).to have_selector('.event-title', exact_text: "left project #{project.full_name}")
    end
  end

  context 'when a users membership expires for the project' do
    before do
      visit_activities_with_event(:expired)
    end

    it "presents the correct message" do
      expect(page).to have_selector('.event-user-info', exact_text: "#{user.name} #{user.to_reference}")
      expect(page).to have_selector('.event-title',
        exact_text: "removed due to membership expiration from project #{project.full_name}")
    end
  end
end
