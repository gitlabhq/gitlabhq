require 'spec_helper'

feature 'Groups > Members > Member cannot request access to his project', feature: true do
  let(:member) { create(:user) }
  let(:group) { create(:group) }

  background do
    group.add_developer(member)
    login_as(member)
    visit group_path(group)
  end

  scenario 'member does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
