# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User updates wiki page' do
  include WikiHelpers

  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when wiki is empty' do
    before do |example|
      visit(project_wikis_path(project))

      wait_for_svg_to_be_loaded(example)

      click_link "Create your first page"
    end

    context 'in a user namespace' do
      let(:project) { create(:project, :wiki_repo) }

      it 'redirects back to the home edit page' do
        page.within(:css, '.wiki-form .form-actions') do
          click_on('Cancel')
        end

        expect(current_path).to eq project_wiki_path(project, :home)
      end

      it 'updates a page that has a path', :js do
        fill_in(:wiki_title, with: 'one/two/three-test')

        page.within '.wiki-form' do
          fill_in(:wiki_content, with: 'wiki content')
          click_on('Create page')
        end

        expect(current_path).to include('one/two/three-test')
        expect(find('.wiki-pages')).to have_content('three')

        first(:link, text: 'three').click

        expect(find('.nav-text')).to have_content('three')

        click_on('Edit')

        expect(current_path).to include('one/two/three-test')
        expect(page).to have_content('Edit Page')

        fill_in('Content', with: 'Updated Wiki Content')
        click_on('Save changes')

        expect(page).to have_content('Updated Wiki Content')
      end

      it_behaves_like 'wiki file attachments'
    end
  end

  context 'when wiki is not empty' do
    let(:project_wiki) { create(:project_wiki, project: project, user: project.creator) }
    let!(:wiki_page) { create(:wiki_page, wiki: project_wiki, title: 'home', content: 'Home page') }

    before do
      visit(project_wikis_path(project))

      click_link('Edit')
    end

    context 'in a user namespace' do
      let(:project) { create(:project, :wiki_repo) }

      it 'updates a page', :js do
        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Update home')

        fill_in(:wiki_content, with: 'My awesome wiki!')
        click_button('Save changes')

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end

      it 'updates the commit message as the title is changed', :js do
        fill_in(:wiki_title, with: '& < > \ \ { } &')

        expect(page).to have_field('wiki[message]', with: 'Update & < > \ \ { } &')
      end

      it 'correctly escapes the commit message entities', :js do
        fill_in(:wiki_title, with: 'Wiki title')

        expect(page).to have_field('wiki[message]', with: 'Update Wiki title')
      end

      it 'shows a validation error message' do
        fill_in(:wiki_content, with: '')
        click_button('Save changes')

        expect(page).to have_selector('.wiki-form')
        expect(page).to have_content('Edit Page')
        expect(page).to have_content('The form contains the following error:')
        expect(page).to have_content("Content can't be blank")
        expect(find('textarea#wiki_content').value).to eq('')
      end

      it 'shows the emoji autocompletion dropdown', :js do
        find('#wiki_content').native.send_keys('')
        fill_in(:wiki_content, with: ':')

        expect(page).to have_selector('.atwho-view')
      end

      it 'shows the error message' do
        wiki_page.update(content: 'Update')

        click_button('Save changes')

        expect(page).to have_content('Someone edited the page the same time you did.')
      end

      it 'updates a page' do
        fill_in('Content', with: 'Updated Wiki Content')
        click_on('Save changes')

        expect(page).to have_content('Updated Wiki Content')
      end

      it 'cancels editing of a page' do
        page.within(:css, '.wiki-form .form-actions') do
          click_on('Cancel')
        end

        expect(current_path).to eq(project_wiki_path(project, wiki_page))
      end

      it_behaves_like 'wiki file attachments'
    end

    context 'in a group namespace' do
      let(:project) { create(:project, :wiki_repo, namespace: create(:group, :public)) }

      it 'updates a page', :js do
        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Update home')

        fill_in(:wiki_content, with: 'My awesome wiki!')

        click_button('Save changes')

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end

      it_behaves_like 'wiki file attachments'
    end
  end

  context 'when the page is in a subdir' do
    let!(:project) { create(:project, :wiki_repo) }
    let(:project_wiki) { create(:project_wiki, project: project, user: project.creator) }
    let(:page_name) { 'page_name' }
    let(:page_dir) { "foo/bar/#{page_name}" }
    let!(:wiki_page) { create(:wiki_page, wiki: project_wiki, title: page_dir, content: 'Home page') }

    before do
      visit(project_wiki_edit_path(project, wiki_page))
    end

    it 'moves the page to the root folder' do
      fill_in(:wiki_title, with: "/#{page_name}")

      click_button('Save changes')

      expect(current_path).to eq(project_wiki_path(project, page_name))
    end

    it 'moves the page to other dir' do
      new_page_dir = "foo1/bar1/#{page_name}"

      fill_in(:wiki_title, with: new_page_dir)

      click_button('Save changes')

      expect(current_path).to eq(project_wiki_path(project, new_page_dir))
    end

    it 'remains in the same place if title has not changed' do
      original_path = project_wiki_path(project, wiki_page)

      fill_in(:wiki_title, with: page_name)

      click_button('Save changes')

      expect(current_path).to eq(original_path)
    end

    it 'can be moved to a different dir with a different name' do
      new_page_dir = "foo1/bar1/new_page_name"

      fill_in(:wiki_title, with: new_page_dir)

      click_button('Save changes')

      expect(current_path).to eq(project_wiki_path(project, new_page_dir))
    end

    it 'can be renamed and moved to the root folder' do
      new_name = 'new_page_name'

      fill_in(:wiki_title, with: "/#{new_name}")

      click_button('Save changes')

      expect(current_path).to eq(project_wiki_path(project, new_name))
    end

    it 'squishes the title before creating the page' do
      new_page_dir = "  foo1 /  bar1  /  #{page_name}  "

      fill_in(:wiki_title, with: new_page_dir)

      click_button('Save changes')

      expect(current_path).to eq(project_wiki_path(project, "foo1/bar1/#{page_name}"))
    end

    it_behaves_like 'wiki file attachments'
  end
end
