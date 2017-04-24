require 'spec_helper'

feature 'Groups > Contribution Analytics', js: true, feature: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:empty_project) { create(:empty_project, namespace: group) }

  before do
    group.add_owner(user)
    login_with(user)
  end

  describe 'visit Contribution Analytics page for group' do
    it 'displays Contribution Analytics' do
      visit group_path(group)

      click_link 'Contribution Analytics'

      expect(page).to have_content "Contribution analytics for issues, merge requests and push"
    end
  end
end
