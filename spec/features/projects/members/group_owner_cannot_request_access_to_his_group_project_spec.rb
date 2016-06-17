require 'spec_helper'

feature 'Projects > Members > Group owner cannot request access to his group project', feature: true do
  let(:owner) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  background do
    group.add_owner(owner)
    login_as(owner)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'owner does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
