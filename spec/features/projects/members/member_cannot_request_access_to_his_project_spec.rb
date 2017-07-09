require 'spec_helper'

feature 'Projects > Members > Member cannot request access to his project', feature: true do
  let(:member) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [member, :developer]
    sign_in(member)
    visit project_path(project)
  end

  scenario 'member does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
