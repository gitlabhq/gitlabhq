require 'spec_helper'

describe 'User updates wiki page' do
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'when wiki is empty' do
    before do
      visit(project_wikis_path(project))
    end

    context 'in a user namespace' do
      let(:project) { create(:project, namespace: user.namespace) }

      it 'redirects back to the home edit page' do
        page.within(:css, '.wiki-form .form-actions') do
          click_on('Cancel')
        end

        expect(current_path).to eq project_wiki_path(project, :home)
      end

      it 'updates a page that has a path', :js do
        click_on('New page')

        page.within('#modal-new-wiki') do
          fill_in(:new_wiki_path, with: 'one/two/three-test')
          click_on('Create page')
        end

        page.within '.wiki-form' do
          fill_in(:wiki_content, with: 'wiki content')
          click_on('Create page')
        end

        expect(current_path).to include('one/two/three-test')
        expect(find('.wiki-pages')).to have_content('Three')

        first(:link, text: 'Three').click

        expect(find('.nav-text')).to have_content('Three')

        click_on('Edit')

        expect(current_path).to include('one/two/three-test')
        expect(page).to have_content('Edit Page')

        fill_in('Content', with: 'Updated Wiki Content')
        click_on('Save changes')

        expect(page).to have_content('Updated Wiki Content')
      end
    end
  end

  context 'when wiki is not empty' do
    let(:project_wiki) { create(:project_wiki, project: project, user: project.creator) }
    let!(:wiki_page) { create(:wiki_page, wiki: project_wiki, attrs: { title: 'home', content: 'Home page' }) }

    before do
      visit(project_wikis_path(project))
    end

    context 'in a user namespace' do
      let(:project) { create(:project, namespace: user.namespace) }

      it 'updates a page' do
        click_link('Edit')

        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Update home')

        fill_in(:wiki_content, with: 'My awesome wiki!')
        click_button('Save changes')

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end

      it 'shows a validation error message' do
        click_link('Edit')

        fill_in(:wiki_content, with: '')
        click_button('Save changes')

        expect(page).to have_selector('.wiki-form')
        expect(page).to have_content('Edit Page')
        expect(page).to have_content('The form contains the following error:')
        expect(page).to have_content("Content can't be blank")
        expect(find('textarea#wiki_content').value).to eq('')
      end

      it 'shows the autocompletion dropdown', :js do
        click_link('Edit')

        find('#wiki_content').native.send_keys('')
        fill_in(:wiki_content, with: '@')

        expect(page).to have_selector('.atwho-view')
      end

      it 'shows the error message' do
        click_link('Edit')

        wiki_page.update(content: 'Update')

        click_button('Save changes')

        expect(page).to have_content('Someone edited the page the same time you did.')
      end

      it 'updates a page' do
        click_on('Edit')
        fill_in('Content', with: 'Updated Wiki Content')
        click_on('Save changes')

        expect(page).to have_content('Updated Wiki Content')
      end

      it 'cancels edititng of a page' do
        click_on('Edit')

        page.within(:css, '.wiki-form .form-actions') do
          click_on('Cancel')
        end

        expect(current_path).to eq(project_wiki_path(project, wiki_page))
      end
    end

    context 'in a group namespace' do
      let(:project) { create(:project, namespace: create(:group, :public)) }

      it 'updates a page' do
        click_link('Edit')

        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Update home')

        fill_in(:wiki_content, with: 'My awesome wiki!')
        click_button('Save changes')

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end
  end
end
