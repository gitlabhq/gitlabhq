require 'spec_helper'

feature 'Projects > Wiki > User updates wiki page' do
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
    sign_in(user)

    visit project_wikis_path(project)
  end

  context 'in the user namespace' do
    let(:project) { create(:project, namespace: user.namespace) }

    context 'the home page' do
      scenario 'success when the wiki content is not empty' do
        click_link 'Edit'

        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Update home')

        fill_in :wiki_content, with: 'My awesome wiki!'
        click_button 'Save changes'

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end

      scenario 'failure when the wiki content is empty' do
        click_link 'Edit'

        fill_in :wiki_content, with: ''
        click_button 'Save changes'

        expect(page).to have_selector('.wiki-form')
        expect(page).to have_content('Edit Page')
        expect(page).to have_content('The form contains the following error:')
        expect(page).to have_content('Content can\'t be blank')
        expect(find('textarea#wiki_content').value).to eq ''
      end

      scenario 'content has autocomplete', :js do
        click_link 'Edit'

        find('#wiki_content').native.send_keys('')
        fill_in :wiki_content, with: '@'

        expect(page).to have_selector('.atwho-view')
      end
    end
  end

  context 'in a group namespace' do
    let(:project) { create(:project, namespace: create(:group, :public)) }

    scenario 'the home page' do
      click_link 'Edit'

      # Commit message field should have correct value.
      expect(page).to have_field('wiki[message]', with: 'Update home')

      fill_in :wiki_content, with: 'My awesome wiki!'
      click_button 'Save changes'

      expect(page).to have_content('Home')
      expect(page).to have_content("Last edited by #{user.name}")
      expect(page).to have_content('My awesome wiki!')
    end
  end
end
