require 'spec_helper'

feature 'Projects > Members > Owner cannot leave project', feature: true do
  let(:owner) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [owner, :owner]
    login_as(owner)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'user does not see a "Leave Project" link' do
    expect(page).not_to have_content 'Leave Project'
  end
end
