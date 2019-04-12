require 'spec_helper'

describe 'Dashboard > User filters projects' do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Victorialand', namespace: user.namespace) }
  let(:user2) { create(:user) }
  let(:project2) { create(:project, name: 'Treasure', namespace: user2.namespace) }

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

    it 'will autocomplete searches', :js do
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
      click_sort_direction
      list = page.all('.projects-list .project-name').map(&:text)
      expect(list).to match(sorted_projects)
    end

    describe 'Search' do
      it 'will execute when i click the search button' do
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
        priv = create(:project, :private, name: 'Private project', namespace: user.namespace)
        int = create(:project, :internal, name: 'Internal project', namespace: user.namespace)

        priv.add_maintainer(user)
        int.add_maintainer(user)
      end

      it 'can filter for only private projects' do
        select_dropdown_option '#filtered-search-visibility-dropdown', 'Private'
        expect(current_url).to match(/visibility_level=0/)
        list = page.all('.projects-list .project-name').map(&:text)
        expect(list).to match(["Private project", "Treasure", "Victorialand"])
      end

      it 'can filter for only internal projects' do
        select_dropdown_option '#filtered-search-visibility-dropdown', 'Internal'
        expect(current_url).to match(/visibility_level=10/)
        list = page.all('.projects-list .project-name').map(&:text)
        expect(list).to match(['Internal project'])
      end

      it 'can filter for any project' do
        select_dropdown_option '#filtered-search-visibility-dropdown', 'Any'
        list = page.all('.projects-list .project-name').map(&:text)
        expect(list).to match(["Internal project", "Private project", "Treasure", "Victorialand"])
      end
    end

    describe 'Sorting' do
      before do
        [
          { name: 'Red ribbon army', created_at: 2.days.ago },
          { name: 'Cell saga', created_at: Time.now },
          { name: 'Frieza saga', created_at: 10.days.ago }
        ].each do |item|
          proj = create(:project, name: item[:name], namespace: user.namespace, created_at: item[:created_at])
          proj.add_developer(user)
        end

        user.toggle_star(project)
        user.toggle_star(project2)
        user2.toggle_star(project2)
      end

      it 'will include sorting direction' do
        sorting_dropdown = page.find('.filtered-search-block #filtered-search-sorting-dropdown')
        expect(sorting_dropdown).to have_css '.reverse-sort-btn'
      end

      it 'will have all sorting options', :js do
        sorting_dropdown = page.find('.filtered-search-block #filtered-search-sorting-dropdown')
        sorting_option_labels = ['Last updated', 'Created date', 'Name', 'Stars']

        sorting_dropdown.click

        sorting_option_labels.each do |label|
          expect(sorting_dropdown).to have_content(label)
        end
      end

      it 'will default to Last updated', :js do
        page.find('.filtered-search-block #filtered-search-sorting-dropdown').click
        active_sorting_option = page.first('.filtered-search-block #filtered-search-sorting-dropdown .is-active')

        expect(active_sorting_option).to have_content 'Last updated'
      end

      context 'Sorting by name' do
        it 'will sort the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Name'

          desc = ['Victorialand', 'Treasure', 'Red ribbon army', 'Frieza saga', 'Cell saga']
          asc = ['Cell saga', 'Frieza saga', 'Red ribbon army', 'Treasure', 'Victorialand']

          expect_to_see_projects(desc)
          expect_to_see_projects(asc)
        end

        it 'will update the url query' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Name'

          [/sort=name_desc/, /sort=name_asc/].each do |query_param|
            click_sort_direction
            expect(current_url).to match(query_param)
          end
        end
      end

      context 'Sorting by Last updated' do
        it 'will sort the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Last updated'

          desc = ["Frieza saga", "Red ribbon army", "Victorialand", "Treasure", "Cell saga"]
          asc = ["Cell saga", "Treasure", "Victorialand", "Red ribbon army", "Frieza saga"]

          expect_to_see_projects(desc)
          expect_to_see_projects(asc)
        end

        it 'will update the url query' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Last updated'

          [/sort=latest_activity_asc/, /sort=latest_activity_desc/].each do |query_param|
            click_sort_direction
            expect(current_url).to match(query_param)
          end
        end
      end

      context 'Sorting by Created date' do
        it 'will sort the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Created date'

          desc = ["Frieza saga", "Red ribbon army", "Victorialand", "Treasure", "Cell saga"]
          asc = ["Cell saga", "Treasure", "Victorialand", "Red ribbon army", "Frieza saga"]

          expect_to_see_projects(desc)
          expect_to_see_projects(asc)
        end

        it 'will update the url query' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Created date'

          [/sort=created_asc/, /sort=created_desc/].each do |query_param|
            click_sort_direction
            expect(current_url).to match(query_param)
          end
        end
      end

      context 'Sorting by Stars' do
        it 'will sort the project list' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Stars'

          desc = ["Red ribbon army", "Cell saga", "Frieza saga", "Victorialand", "Treasure"]
          asc = ["Treasure", "Victorialand", "Red ribbon army", "Cell saga", "Frieza saga"]

          expect_to_see_projects(desc)
          expect_to_see_projects(asc)
        end

        it 'will update the url query' do
          select_dropdown_option '#filtered-search-sorting-dropdown', 'Stars'

          [/sort=stars_asc/, /sort=stars_desc/].each do |query_param|
            click_sort_direction
            expect(current_url).to match(query_param)
          end
        end
      end
    end
  end
end
