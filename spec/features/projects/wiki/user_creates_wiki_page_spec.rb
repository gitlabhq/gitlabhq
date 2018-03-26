require 'spec_helper'

describe 'User creates wiki page' do
  let(:user) { create(:user) }
  let(:wiki) { ProjectWiki.new(project, user) }
  let(:project) { create(:project) }

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

      it 'shows validation error message' do
        page.within('.wiki-form') do
          fill_in(:wiki_content, with: '')
          click_on('Create page')
        end

        expect(page).to have_content('The form contains the following error:')
        expect(page).to have_content("Content can't be blank")

        page.within('.wiki-form') do
          fill_in(:wiki_content, with: '[link test](test)')
          click_on('Create page')
        end

        expect(page).to have_content('Home')
        expect(page).to have_content('link test')

        click_link('link test')

        expect(page).to have_content('Create Page')
      end

      it 'shows non-escaped link in the pages list', :js do
        click_link('New page')

        page.within('#modal-new-wiki') do
          fill_in(:new_wiki_path, with: 'one/two/three-test')
          click_on('Create page')
        end

        page.within('.wiki-form') do
          fill_in(:wiki_content, with: 'wiki content')
          click_on('Create page')
        end

        expect(current_path).to include('one/two/three-test')
        expect(page).to have_xpath("//a[@href='/#{project.full_path}/wikis/one/two/three-test']")
      end

      it 'has "Create home" as a commit message' do
        expect(page).to have_field('wiki[message]', with: 'Create home')
      end

      it 'creates a page from the home page' do
        fill_in(:wiki_content, with: 'My awesome wiki!')

        page.within('.wiki-form') do
          click_button('Create page')
        end

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end

      it 'creates ASCII wiki with LaTeX blocks', :js do
        stub_application_setting(plantuml_url: 'http://localhost', plantuml_enabled: true)

        ascii_content = <<~MD
          :stem: latexmath

          [stem]
          ++++
          \\sqrt{4} = 2
          ++++

          another part

          [latexmath]
          ++++
          \\beta_x \\gamma
          ++++

          stem:[2+2] is 4
        MD

        find('#wiki_format option[value=asciidoc]').select_option
        fill_in(:wiki_content, with: ascii_content)

        page.within('.wiki-form') do
          click_button('Create page')
        end

        page.within '.wiki' do
          expect(page).to have_selector('.katex', count: 3)
          expect(page).to have_content('2+2 is 4')
        end
      end
    end

    context 'in a group namespace', :js do
      let(:project) { create(:project, namespace: create(:group, :public)) }

      it 'has "Create home" as a commit message' do
        expect(page).to have_field('wiki[message]', with: 'Create home')
      end

      it 'creates a page from from the home page' do
        page.within('.wiki-form') do
          fill_in(:wiki_content, with: 'My awesome wiki!')
          click_button('Create page')
        end

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end
  end

  context 'when wiki is not empty', :js do
    before do
      create(:wiki_page, wiki: wiki, attrs: { title: 'home', content: 'Home page' })

      visit(project_wikis_path(project))
    end

    context 'in a user namespace' do
      let(:project) { create(:project, namespace: user.namespace) }

      context 'via the "new wiki page" page' do
        it 'creates a page with a single word' do
          click_link('New page')

          page.within('#modal-new-wiki') do
            fill_in(:new_wiki_path, with: 'foo')
            click_button('Create page')
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create foo')

          page.within('.wiki-form') do
            fill_in(:wiki_content, with: 'My awesome wiki!')
            click_button('Create page')
          end

          expect(page).to have_content('Foo')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end

        it 'creates a page with spaces in the name' do
          click_link('New page')

          page.within('#modal-new-wiki') do
            fill_in(:new_wiki_path, with: 'Spaces in the name')
            click_button('Create page')
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create spaces in the name')

          page.within('.wiki-form') do
            fill_in(:wiki_content, with: 'My awesome wiki!')
            click_button('Create page')
          end

          expect(page).to have_content('Spaces in the name')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end

        it 'creates a page with hyphens in the name' do
          click_link('New page')

          page.within('#modal-new-wiki') do
            fill_in(:new_wiki_path, with: 'hyphens-in-the-name')
            click_button('Create page')
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create hyphens in the name')

          page.within('.wiki-form') do
            fill_in(:wiki_content, with: 'My awesome wiki!')
            click_button('Create page')
          end

          expect(page).to have_content('Hyphens in the name')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end
      end

      it 'shows the autocompletion dropdown' do
        click_link('New page')

        page.within('#modal-new-wiki') do
          fill_in(:new_wiki_path, with: 'test-autocomplete')
          click_button('Create page')
        end

        page.within('.wiki-form') do
          find('#wiki_content').native.send_keys('')
          fill_in(:wiki_content, with: '@')
        end

        expect(page).to have_selector('.atwho-view')
      end
    end

    context 'in a group namespace' do
      let(:project) { create(:project, namespace: create(:group, :public)) }

      context 'via the "new wiki page" page' do
        it 'creates a page' do
          click_link('New page')

          page.within('#modal-new-wiki') do
            fill_in(:new_wiki_path, with: 'foo')
            click_button('Create page')
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create foo')

          page.within('.wiki-form') do
            fill_in(:wiki_content, with: 'My awesome wiki!')
            click_button('Create page')
          end

          expect(page).to have_content('Foo')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end
      end
    end
  end

  describe 'sidebar feature' do
    context 'when the wiki is empty' do
      it 'renders my customized sidebar' do
        create(:wiki_page, wiki: wiki, attrs: { title: '_sidebar', content: 'My customized sidebar' })

        visit(project_wikis_path(project))

        expect(page).to have_content('My customized sidebar')
      end
    end

    context 'when there are some existing pages' do
      before do
        create(:wiki_page, wiki: wiki, attrs: { title: 'home', content: 'home' })
        create(:wiki_page, wiki: wiki, attrs: { title: 'another', content: 'another' })
      end

      it 'renders a default sidebar when there is no customized sidebar' do
        visit(project_wikis_path(project))

        expect(page).to have_content('Another')
        expect(page).to have_content('More Pages')
      end

      context 'when there is a customized sidebar' do
        before do
          create(:wiki_page, wiki: wiki, attrs: { title: '_sidebar', content: 'My customized sidebar' })
        end

        it 'renders my customized sidebar instead of the default one' do
          visit(project_wikis_path(project))

          expect(page).to have_content('My customized sidebar')
          expect(page).not_to have_content('Another')
          expect(page).not_to have_content('More Pages')
        end
      end
    end
  end
end
