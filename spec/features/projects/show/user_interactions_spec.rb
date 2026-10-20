# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User interactions', feature_category: :groups_and_projects do
  describe 'Project stars', :js, :with_current_organization do
    let_it_be(:project) { create(:project, :public, :repository) }

    context 'when user is signed in', :js do
      let(:user) { create(:user, organization: current_organization) }

      before do
        sign_in(user)
        visit(project_path(project))
      end

      it 'validates starring a project' do
        project.add_owner(user)

        star_project

        visit(member_dashboard_projects_path)
        wait_for_requests

        expect(find_by_testid('stars-btn')).to have_content('1')
      end

      it 'validates un-starring a project' do
        project.add_owner(user)

        star_project

        unstar_project

        visit(member_dashboard_projects_path)
        wait_for_requests

        expect(find_by_testid('stars-btn')).to have_content('0')
      end
    end

    private

    def star_project
      click_button(_('Star'))
      wait_for_requests
    end

    def unstar_project
      click_button(_('Unstar'))
      wait_for_requests
    end
  end

  describe 'Collaboration links', :js do
    let_it_be_with_reload(:project1) { create(:project, :repository, :public) }
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    def find_new_menu_toggle
      find_by_testid('base-dropdown-toggle', visible: :all, text: 'Create new…')
    end

    def within_navigation_panel(&block)
      within('.super-topbar', &block)
    end

    context 'with developer user' do
      before_all do
        project1.add_developer(user)
      end

      it 'shows all the expected links' do
        visit project_path(project1)

        # The navigation bar
        within_navigation_panel do
          find_new_menu_toggle.click

          aggregate_failures 'dropdown links in the navigation bar' do
            expect(page).to have_button('New work item')
            expect(page).to have_link('New merge request')
            expect(page).to have_link('New snippet', href: new_project_snippet_path(project1))
          end

          find_new_menu_toggle.click
        end

        # The dropdown above the tree
        page.within('.tree-controls') do
          find('.add-to-tree').click

          aggregate_failures 'dropdown links above the repo tree' do
            expect(page).to have_button('New file')
            expect(page).to have_button('Upload file')
            expect(page).to have_button('New directory')
            expect(page).to have_button('New branch')
            expect(page).to have_button('New tag')
          end
        end

        # The Web IDE
        within_testid('code-dropdown') do
          click_button 'Code'
        end
        expect(page).to have_link('Web IDE')
      end

      it 'hides the links when the project is archived' do
        project1.update!(archived: true)

        visit project_path(project1)

        within_navigation_panel do
          find_new_menu_toggle.click

          aggregate_failures 'dropdown links' do
            expect(page).not_to have_link('New issue')
            expect(page).not_to have_link('New merge request')
            expect(page).not_to have_link('New snippet', href: new_project_snippet_path(project1))
          end

          find_new_menu_toggle.click
        end

        expect(page).not_to have_selector('[data-testid="add-to-tree"]')

        within_testid('code-dropdown') do
          click_button('Code')
          expect(page).not_to have_button('Edit')
          expect(page).not_to have_link('Web IDE')
        end
      end
    end
  end
end
