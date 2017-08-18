require 'spec_helper'

feature 'Projects > Members > Group member cannot leave group project' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  background do
    group.add_developer(user)
    sign_in(user)
    visit project_path(project)
  end

  scenario 'user does not see a "Leave project" link' do
    expect(page).not_to have_content 'Leave project'
  end
end
