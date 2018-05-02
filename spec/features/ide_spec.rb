require 'spec_helper'

describe 'IDE', :js do
  describe 'sub-groups' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:subgroup_project) { create(:project, :repository, namespace: subgroup) }

    before do
      subgroup_project.add_master(user)
      sign_in(user)

      visit project_path(subgroup_project)

      click_link('Web IDE')

      wait_for_requests
    end

    it 'loads project in web IDE' do
      expect(page).to have_selector('.context-header', text: subgroup_project.name)
    end
  end
end
