# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Collaboration links', :js, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  def find_new_menu_toggle
    find_by_testid('base-dropdown-toggle', text: 'Create new...')
  end

  context 'with developer user' do
    before_all do
      project.add_developer(user)
    end

    it 'shows all the expected links' do
      visit project_path(project)

      # The navigation bar
      within_testid('super-sidebar') do
        find_new_menu_toggle.click

        aggregate_failures 'dropdown links in the navigation bar' do
          expect(page).to have_link('New issue')
          expect(page).to have_link('New merge request')
          expect(page).to have_link('New snippet', href: new_project_snippet_path(project))
        end

        find_new_menu_toggle.click
      end

      # The dropdown above the tree
      page.within('.repo-breadcrumb') do
        find_by_testid('add-to-tree').click

        aggregate_failures 'dropdown links above the repo tree' do
          expect(page).to have_link('New file')
          expect(page).to have_button('Upload file')
          expect(page).to have_button('New directory')
          expect(page).to have_link('New branch')
          expect(page).to have_link('New tag')
        end
      end

      # The Web IDE
      click_button 'Edit'
      expect(page).to have_button('Web IDE')
    end

    it 'hides the links when the project is archived' do
      project.update!(archived: true)

      visit project_path(project)

      within_testid('super-sidebar') do
        find_new_menu_toggle.click

        aggregate_failures 'dropdown links' do
          expect(page).not_to have_link('New issue')
          expect(page).not_to have_link('New merge request')
          expect(page).not_to have_link('New snippet', href: new_project_snippet_path(project))
        end

        find_new_menu_toggle.click
      end

      expect(page).not_to have_selector('[data-testid="add-to-tree"]')

      expect(page).not_to have_button('Edit')
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
        project.project_feature.update!({ merge_requests_access_level: merge_requests_access_level })
        project.add_member(user, user_level)
        visit project_path(project)
      end

      it "updates Web IDE link" do
        expect(page.has_button?('Edit')).to be(expect_ide_link)
      end
    end
  end
end
