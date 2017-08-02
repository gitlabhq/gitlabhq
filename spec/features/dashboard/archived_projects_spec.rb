require 'spec_helper'

RSpec.describe 'Dashboard Archived Project' do
  let(:user) { create :user }
  let(:project) { create :project}
  let(:archived_project) { create(:project, :archived) }

  before do
    project.team << [user, :master]
    archived_project.team << [user, :master]

    sign_in(user)

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

  it 'searchs archived projects', :js do
    click_button 'Last updated'
    click_link 'Show archived projects'

    expect(page).to have_link(project.name)
    expect(page).to have_link(archived_project.name)

    fill_in 'project-filter-form-field', with: archived_project.name

    find('#project-filter-form-field').native.send_keys :return

    expect(page).not_to have_link(project.name)
    expect(page).to have_link(archived_project.name)
  end
end
