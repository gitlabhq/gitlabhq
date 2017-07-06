require 'spec_helper'

feature 'Projects > Wiki > User creates wiki page', :js do
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    sign_in(user)

    visit project_path(project)
  end

  context 'in the user namespace' do
    let(:project) { create(:project, namespace: user.namespace) }

    context 'when wiki is empty' do
      before do
        find('.shortcuts-wiki').trigger('click')
      end

      scenario 'commit message field has value "Create home"' do
        expect(page).to have_field('wiki[message]', with: 'Create home')
      end

      scenario 'directly from the wiki home page' do
        fill_in :wiki_content, with: 'My awesome wiki!'
        page.within '.wiki-form' do
          click_button 'Create page'
        end
        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end

      scenario 'creates ASCII wiki with LaTeX blocks' do
        stub_application_setting(plantuml_url: 'http://localhost', plantuml_enabled: true)

        ascii_content = <<~MD
          :stem: latexmath

          [stem]
          ++++
          \sqrt{4} = 2
          ++++

          another part

          [latexmath]
          ++++
          \beta_x \gamma
          ++++

          stem:[2+2] is 4
        MD

        find('#wiki_format option[value=asciidoc]').select_option
        fill_in :wiki_content, with: ascii_content

        page.within '.wiki-form' do
          click_button 'Create page'
        end

        page.within '.wiki' do
          expect(page).to have_selector('.katex', count: 3)
          expect(page).to have_content('2+2 is 4')
        end
      end
    end

    context 'when wiki is not empty' do
      before do
        WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
        find('.shortcuts-wiki').trigger('click')
      end

      context 'via the "new wiki page" page' do
        scenario 'when the wiki page has a single word name' do
          click_link 'New page'

          page.within '#modal-new-wiki' do
            fill_in :new_wiki_path, with: 'foo'
            click_button 'Create page'
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create foo')

          page.within '.wiki-form' do
            fill_in :wiki_content, with: 'My awesome wiki!'
            click_button 'Create page'
          end

          expect(page).to have_content('Foo')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end

        scenario 'when the wiki page has spaces in the name' do
          click_link 'New page'

          page.within '#modal-new-wiki' do
            fill_in :new_wiki_path, with: 'Spaces in the name'
            click_button 'Create page'
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create spaces in the name')

          page.within '.wiki-form' do
            fill_in :wiki_content, with: 'My awesome wiki!'
            click_button 'Create page'
          end

          expect(page).to have_content('Spaces in the name')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end

        scenario 'when the wiki page has hyphens in the name' do
          click_link 'New page'

          page.within '#modal-new-wiki' do
            fill_in :new_wiki_path, with: 'hyphens-in-the-name'
            click_button 'Create page'
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create hyphens in the name')

          page.within '.wiki-form' do
            fill_in :wiki_content, with: 'My awesome wiki!'
            click_button 'Create page'
          end

          expect(page).to have_content('Hyphens in the name')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end
      end

      scenario 'content has autocomplete' do
        click_link 'New page'

        page.within '#modal-new-wiki' do
          fill_in :new_wiki_path, with: 'test-autocomplete'
          click_button 'Create page'
        end

        page.within '.wiki-form' do
          find('#wiki_content').native.send_keys('')
          fill_in :wiki_content, with: '@'
        end

        expect(page).to have_selector('.atwho-view')
      end
    end
  end

  context 'in a group namespace' do
    let(:project) { create(:project, namespace: create(:group, :public)) }

    context 'when wiki is empty' do
      before do
        find('.shortcuts-wiki').trigger('click')
      end

      scenario 'commit message field has value "Create home"' do
        expect(page).to have_field('wiki[message]', with: 'Create home')
      end

      scenario 'directly from the wiki home page' do
        fill_in :wiki_content, with: 'My awesome wiki!'
        page.within '.wiki-form' do
          click_button 'Create page'
        end

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end

    context 'when wiki is not empty' do
      before do
        WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
        find('.shortcuts-wiki').trigger('click')
      end

      scenario 'via the "new wiki page" page' do
        click_link 'New page'

        page.within '#modal-new-wiki' do
          fill_in :new_wiki_path, with: 'foo'
          click_button 'Create page'
        end

        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Create foo')

        page.within '.wiki-form' do
          fill_in :wiki_content, with: 'My awesome wiki!'
          click_button 'Create page'
        end

        expect(page).to have_content('Foo')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end
  end
end
