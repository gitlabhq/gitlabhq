require 'spec_helper'

describe 'User views a wiki page' do
  shared_examples 'wiki page user view' do
    let(:user) { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }
    let(:wiki_page) do
      create(:wiki_page,
        wiki: project.wiki,
        attrs: { title: 'home', content: 'Look at this [image](image.jpg)\n\n ![alt text](image.jpg)' })
    end

    before do
      project.add_master(user)
      sign_in(user)
    end

    context 'when wiki is empty' do
      before do
        visit(project_wikis_path(project))

        click_on('New page')

        page.within('#modal-new-wiki') do
          fill_in(:new_wiki_path, with: 'one/two/three-test')
          click_on('Create page')
        end

        page.within('.wiki-form') do
          fill_in(:wiki_content, with: 'wiki content')
          click_on('Create page')
        end
      end

      it 'shows the history of a page that has a path', :js do
        expect(current_path).to include('one/two/three-test')

        first(:link, text: 'Three').click
        click_on('Page history')

        expect(current_path).to include('one/two/three-test')

        page.within(:css, '.nav-text') do
          expect(page).to have_content('History')
        end
      end

      it 'shows an old version of a page', :js do
        expect(current_path).to include('one/two/three-test')
        expect(find('.wiki-pages')).to have_content('Three')

        first(:link, text: 'Three').click

        expect(find('.nav-text')).to have_content('Three')

        click_on('Edit')

        expect(current_path).to include('one/two/three-test')
        expect(page).to have_content('Edit Page')

        fill_in('Content', with: 'Updated Wiki Content')

        click_on('Save changes')
        click_on('Page history')

        page.within(:css, '.nav-text') do
          expect(page).to have_content('History')
        end

        find('a[href*="?version_id"]')
      end
    end

    context 'when a page does not have history' do
      before do
        visit(project_wiki_path(project, wiki_page))
      end

      it 'shows all the pages' do
        expect(page).to have_content(user.name)
        expect(find('.wiki-pages')).to have_content(wiki_page.title.capitalize)
      end

      it 'shows a file stored in a page' do
        gollum_file_double = double('Gollum::File',
                                    mime_type: 'image/jpeg',
                                    name: 'images/image.jpg',
                                    path: 'images/image.jpg',
                                    raw_data: '')
        wiki_file = Gitlab::Git::WikiFile.new(gollum_file_double)

        allow(wiki_file).to receive(:mime_type).and_return('image/jpeg')
        allow_any_instance_of(ProjectWiki).to receive(:find_file).with('image.jpg', nil).and_return(wiki_file)

        expect(page).to have_xpath('//img[@data-src="image.jpg"]')
        expect(page).to have_link('image', href: "#{project.wiki.wiki_base_path}/image.jpg")

        click_on('image')

        expect(current_path).to match('wikis/image.jpg')
        expect(page).not_to have_xpath('/html') # Page should render the image which means there is no html involved
      end

      it 'shows the creation page if file does not exist' do
        expect(page).to have_link('image', href: "#{project.wiki.wiki_base_path}/image.jpg")

        click_on('image')

        expect(current_path).to match('wikis/image.jpg')
        expect(page).to have_content('New Wiki Page')
        expect(page).to have_content('Create page')
      end
    end

    context 'when a page has history' do
      before do
        wiki_page.update(message: 'updated home', content: 'updated [some link](other-page)')
      end

      it 'shows the page history' do
        visit(project_wiki_path(project, wiki_page))

        expect(page).to have_selector('a.btn', text: 'Edit')

        click_on('Page history')

        expect(page).to have_content(user.name)
        expect(page).to have_content("#{user.username} created page: home")
        expect(page).to have_content('updated home')
      end

      it 'does not show the "Edit" button' do
        visit(project_wiki_path(project, wiki_page, version_id: wiki_page.versions.last.id))

        expect(page).not_to have_selector('a.btn', text: 'Edit')
      end
    end

    it 'opens a default wiki page', :js do
      visit(project_path(project))

      find('.shortcuts-wiki').click

      expect(page).to have_content('Home · Create Page')
    end
  end

  context 'when Gitaly is enabled' do
    it_behaves_like 'wiki page user view'
  end

  context 'when Gitaly is disabled', :skip_gitaly_mock do
    it_behaves_like 'wiki page user view'
  end
end
