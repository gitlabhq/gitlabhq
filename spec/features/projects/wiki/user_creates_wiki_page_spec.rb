require 'spec_helper'

feature 'Projects > Wiki > User creates wiki page', feature: true do
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    login_as(user)

    visit namespace_project_path(project.namespace, project)
    click_link 'Wiki'
  end

  context 'wiki project is in the user namespace' do
    let(:project) { create(:project, namespace: user.namespace) }

    context 'when wiki is empty' do
      scenario 'user can create a new wiki page from the wiki home page' do
        expect(page).to have_content('Home · Edit Page')

        fill_in :wiki_content, with: 'My awesome wiki!'
        click_button 'Create page'

        expect(page).to have_content("Home · last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end

    context 'when wiki is not empty' do
      before do
        WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
      end

      scenario 'user can create a new wiki page', js: true do
        click_link 'New Page'

        fill_in :new_wiki_path, with: 'foo'
        click_button 'Create Page'

        expect(page).to have_content('Foo · Edit Page')

        fill_in :wiki_content, with: 'My awesome wiki!'
        click_button 'Create page'

        expect(page).to have_content("Foo · last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end
  end

  context 'wiki project is in the user namespace' do
    let(:project) { create(:project, namespace: create(:group, :public)) }

    context 'when wiki is empty' do
      scenario 'user can create a new wiki page from the wiki home page' do
        expect(page).to have_content('Home · Edit Page')

        fill_in :wiki_content, with: 'My awesome wiki!'
        click_button 'Create page'

        expect(page).to have_content("Home · last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end

    context 'when wiki is not empty' do
      before do
        WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
      end

      scenario 'user can create a new wiki page', js: true do
        click_link 'New Page'

        fill_in :new_wiki_path, with: 'foo'
        click_button 'Create Page'

        expect(page).to have_content('Foo · Edit Page')

        fill_in :wiki_content, with: 'My awesome wiki!'
        click_button 'Create page'

        expect(page).to have_content("Foo · last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end
  end
end
