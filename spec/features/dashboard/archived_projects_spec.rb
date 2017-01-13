require 'spec_helper'

RSpec.describe 'Dashboard Archived Project', feature: true do
  let(:user) { create :user }
  let(:project) { create :project}
  let(:archived_project) { create(:project, :archived) }

  before do
    project.team << [user, :master]
    archived_project.team << [user, :master]

    login_as(user)

    visit dashboard_projects_path
  end

  it 'renders non archived projects' do
    expect(page).to have_link(project.name)
    expect(page).not_to have_link(archived_project.name)
  end

  it 'renders all projects' do
    click_link 'Show archived projects'

    expect(page).to have_link(project.name)
    expect(page).to have_link(archived_project.name)
  end
end
