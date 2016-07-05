require 'spec_helper'

feature 'Projects > Members > Member cannot request access to his project', feature: true do
  let(:member) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [member, :developer]
    login_as(member)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'member does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
