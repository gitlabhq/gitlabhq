require 'spec_helper'

feature 'Projects > Members > Owner cannot request access to his project', feature: true do
  let(:owner) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [owner, :owner]
    login_as(owner)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'owner does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
