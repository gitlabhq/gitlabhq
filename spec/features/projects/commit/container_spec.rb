require 'spec_helper'

describe 'Commit container', :js, :feature do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  it 'keeps container-limited when view type is inline' do
    visit namespace_project_commit_path(project.namespace, project, project.commit.id, view: :inline)

    expect(page).not_to have_selector('.limit-container-width')
  end

  it 'diff spans full width when view type is parallel' do
    visit namespace_project_commit_path(project.namespace, project, project.commit.id, view: :parallel)

    expect(page).to have_selector('.limit-container-width')
  end
end
