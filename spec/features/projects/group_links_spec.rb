require 'spec_helper'

feature 'Project group links', feature: true, js: true do
  include Select2Helper

  let(:master) { create(:user) }
  let(:project) { create(:project) }
  let!(:group) { create(:group) }

  background do
    project.team << [master, :master]
    login_as(master)
  end

  context 'setting an expiration date for a group link' do
    before do
      visit namespace_project_group_links_path(project.namespace, project)

      select2 group.id, from: '#link_group_id'
      fill_in 'expires_at', with: (Time.current + 4.5.days).strftime('%Y-%m-%d')
      page.find('body').click
      click_on 'Share'
    end

    it 'shows the expiration time with a warning class' do
      page.within('.enabled-groups') do
        expect(page).to have_content('expires in 4 days')
        expect(page).to have_selector('.text-warning')
      end
    end
  end
end
