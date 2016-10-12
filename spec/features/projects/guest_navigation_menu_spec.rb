require 'spec_helper'

describe "Guest navigation menu" do
  let(:project) { create :empty_project, :private }
  let(:guest) { create :user }

  before do
    project.team << [guest, :guest]

    login_as(guest)
  end

  it "shows allowed tabs only" do
    visit namespace_project_path(project.namespace, project)

    within(".nav-links") do
      expect(page).to have_content 'Project'
      expect(page).to have_content 'Activity'
      expect(page).to have_content 'Issues'
      expect(page).to have_content 'Wiki'

      expect(page).not_to have_content 'Repository'
      expect(page).not_to have_content 'Pipelines'
      expect(page).not_to have_content 'Graphs'
      expect(page).not_to have_content 'Merge Requests'
    end
  end
end
