require 'spec_helper'

feature 'Delete branch', feature: true, js: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_as user
    visit namespace_project_branches_path(project.namespace, project)
  end

  it 'destroys tooltip' do
    first('.remove-row').hover
    expect(page).to have_selector('.tooltip')

    first('.remove-row').click
    sleep 1

    expect(page).not_to have_selector('.tooltip')
  end
end
