require 'spec_helper'

feature 'Projects > Wiki > User updates wiki page', feature: true do
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    login_as(user)

    visit namespace_project_path(project.namespace, project)
    WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
    click_link 'Wiki'
  end

  context 'wiki project is in the user namespace' do
    let(:project) { create(:project, namespace: user.namespace) }

    scenario 'user can update the wiki home page' do
      click_link 'Edit'

      expect(page).to have_content('Home · Edit Page')

      fill_in :wiki_content, with: 'My awesome wiki!'
      click_button 'Save changes'

      expect(page).to have_content("Home · last edited by #{user.name}")
      expect(page).to have_content('My awesome wiki!')
    end
  end

  context 'wiki project is in the user namespace' do
    let(:project) { create(:project, namespace: create(:group, :public)) }

    scenario 'user can update the wiki home page' do
      click_link 'Edit'

      expect(page).to have_content('Home · Edit Page')

      fill_in :wiki_content, with: 'My awesome wiki!'
      click_button 'Save changes'

      expect(page).to have_content("Home · last edited by #{user.name}")
      expect(page).to have_content('My awesome wiki!')
    end
  end
end
