# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard > User filters projects' do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Victorialand', namespace: user.namespace, created_at: 2.seconds.ago, updated_at: 2.seconds.ago) }
  let(:user2) { create(:user) }
  let(:project2) { create(:project, name: 'Treasure', namespace: user2.namespace, created_at: 1.second.ago, updated_at: 1.second.ago) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'filtering personal projects' do
    before do
      stub_feature_flags(project_list_filter_bar: false)
      project2.add_developer(user)

      visit dashboard_projects_path
    end

    it 'filters by projects "Owned by me"' do
      click_link 'Owned by me'

      expect(page).to have_css('.is-active', text: 'Owned by me')
      expect(page).to have_content('Victorialand')
      expect(page).not_to have_content('Treasure')
    end
  end

  describe 'filtering starred projects', :js do
    before do
      stub_feature_flags(project_list_filter_bar: false)
      user.toggle_star(project)

      visit dashboard_projects_path
    end

    it 'returns message when starred projects fitler returns no results' do
      fill_in 'project-filter-form-field', with: 'Beta\n'

      expect(page).to have_content('This user doesn\'t have any personal projects')
      expect(page).not_to have_content('You don\'t have starred projects yet')
    end
  end

  describe 'without search bar', :js do
    before do
      stub_feature_flags(project_list_filter_bar: false)

      project2.add_developer(user)
      visit dashboard_projects_path
    end

    it 'autocompletes searches upon typing', :js do
      expect(page).to have_content 'Victorialand'
      expect(page).to have_content 'Treasure'

      fill_in 'project-filter-form-field', with: 'Lord beerus\n'

      expect(page).not_to have_content 'Victorialand'
      expect(page).not_to have_content 'Treasure'
    end
  end

  describe 'with search bar', :js do
    before do
      stub_feature_flags(project_list_filter_bar: true)

      project2.add_developer(user)
      visit dashboard_projects_path
    end

    # TODO: move these helpers somewhere more useful
    def click_sort_direction
      page.find('.filtered-search-block #filtered-search-sorting-dropdown .reverse-sort-btn').click
    end

    def select_dropdown_option(selector, label)
      dropdown = page.find(selector)
      dropdown.click

      dropdown.find('.dropdown-menu a', text: label, match: :first).click
    end

    def expect_to_see_projects(sorted_projects)
      list = page.all('.projects-list .project-name').map(&:text)
      expect(list).to match(sorted_projects)
    end

    describe 'Search' do
      it 'executes when the search button is clicked' do
        expect(page).to have_content 'Victorialand'
        expect(page).to have_content 'Treasure'

        fill_in 'project-filter-form-field', with: 'Lord vegeta\n'
        find('.filtered-search .btn').click

        expect(page).not_to have_content 'Victorialand'
        expect(page).not_to have_content 'Treasure'
      end

      it 'will execute when i press enter' do
        expect(page).to have_content 'Victorialand'
        expect(page).to have_content 'Treasure'

        fill_in 'project-filter-form-field', with: 'Lord frieza\n'
        find('#project-filter-form-field').native.send_keys :enter

        expect(page).not_to have_content 'Victorialand'
        expect(page).not_to have_content 'Treasure'
      end
    end

    describe 'Filter' do
      before do
        private_project = create(:project, :private, name: 'Private project', namespace: user.namespace)
        internal_project = create(:project, :internal, name: 'Internal project', namespace: user.namespace)

        private_project.add_maintainer(user)
        internal_project.add_maintainer(user)
      end

      it 'filters private projects only' do
        select_dropdown_option '#filtered-search-visibility-dropdown', 'Private'

        expect(current_url).to match(/visibility_level=0/)

        list = page.all('.projects-list .project-name').map(&:text)

        expect(list).to contain_exactly("Private project", "Treasure", "Victorialand")
      end

      it 'filters internal projects only' do
        select_dropdown_option '#filtered-search-visibility-dropdown', 'Internal'

        expect(current_url).to match(/visibility_level=10/)

        list = page.all('.projects-list .project-name').map(&:text)

        expect(list).to contain_exactly('Internal project')
      end

      it 'filters any project' do
        select_dropdown_option '#filtered-search-visibility-dropdown', 'Any'
        list = page.all('.projects-list .project-name').map(&:text)

        expect(list).to contain_exactly("Internal project", "Private project", "Treasure", "Victorialand")
      end
    end

    describe 'Sorting' do
      let(:desc_sorted_project_names) { %w[Treasure Victorialand] }

      before do
        user.toggle_star(project)
        user.toggle_star(project2)
        user2.toggle_star(project2)
      end

      it 'has all sorting options', :js do
        sorting_dropdown = page.find('.filtered-search-block #filtered-search-sorting-dropdown')

        expect(sorting_dropdown).to have_css '.reverse-sort-btn'

        sorting_dropdown.click

        ['Last updated', 'Created date', 'Name', 'Stars'].each do |label|
          expect(sorting_dropdown).to have_content(label)
        end
      end

      it 'defaults to "Last updated"', :js do
        page.find('.filtered-search-block #filtered-search-sorting-dropdown').click
        active_sorting_option = page.first('.filtered-search-block #filtered-search-sorting-dropdown .is-active')

        expect(active_sorting_option).to have_content 'Last updated'
      end

      context 'Sorting by name' do
        it 'sorts the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Name'

          expect_to_see_projects(desc_sorted_project_names)

          click_sort_direction

          expect_to_see_projects(desc_sorted_project_names.reverse)
        end
      end

      context 'Sorting by Last updated' do
        it 'sorts the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Last updated'

          expect_to_see_projects(desc_sorted_project_names)

          click_sort_direction

          expect_to_see_projects(desc_sorted_project_names.reverse)
        end
      end

      context 'Sorting by Created date' do
        it 'sorts the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Created date'

          expect_to_see_projects(desc_sorted_project_names)

          click_sort_direction

          expect_to_see_projects(desc_sorted_project_names.reverse)
        end
      end

      context 'Sorting by Stars' do
        it 'sorts the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Stars'

          expect_to_see_projects(desc_sorted_project_names)

          click_sort_direction

          expect_to_see_projects(desc_sorted_project_names.reverse)
        end
      end
    end
  end
end
