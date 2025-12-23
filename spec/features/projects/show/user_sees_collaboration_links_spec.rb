# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Collaboration links', :js, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project1) { create(:project, :repository, :public) }
  let_it_be(:project2) { create(:project, :repository, :public) }
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

  context "Web IDE link" do
    where(:merge_requests_access_level, :user_level, :expect_ide_link) do
      ::ProjectFeature::DISABLED | :guest | false
      ::ProjectFeature::DISABLED | :developer | true
      ::ProjectFeature::PRIVATE | :guest | false
      ::ProjectFeature::PRIVATE | :developer | true
      ::ProjectFeature::ENABLED | :guest | true
      ::ProjectFeature::ENABLED | :developer | true
    end

    with_them do
      before do
        project1.project_feature.update!({ merge_requests_access_level: merge_requests_access_level })
        project1.add_member(user, user_level)
        visit project_path(project1)
      end

      it "updates Web IDE link" do
        within_testid('code-dropdown') do
          click_button 'Code'
        end
        expect(page.has_link?('Web IDE')).to be(expect_ide_link)
      end
    end
  end
end
