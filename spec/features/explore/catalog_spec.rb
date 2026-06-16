# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI/CD Catalog', :js, feature_category: :pipeline_composition do
  include GlFilteredSearchHelpers
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:public_projects_with_components) do
    create_list(
      :project,
      3,
      :catalog_resource_with_components,
      :public,
      description: 'A simple component',
      namespace: namespace
    )
  end

  before_all do
    # Set `latest_released_at` inverse to creation order so that sorting by
    # `Released date` produces a different order than sorting by `Created
    # date`. This proves the selected sort option is actually applied in the
    # `Search and sorting` examples below.
    public_projects_with_components.each_with_index do |current_project, index|
      create(
        :ci_catalog_resource,
        :published,
        project: current_project,
        latest_released_at: (1 + (2 * index)).days.ago
      )
    end
  end

  shared_examples 'basic page viewing' do
    it 'shows CI Catalog title and description', :aggregate_failures do
      expect(page).to have_content('CI/CD Catalog')
      expect(page).to have_content(
        'Discover CI/CD components that can improve your pipeline with additional functionality'
      )
    end

    it 'renders CI Catalog resources list' do
      expect(find_all('[data-testid="catalog-resource-item"]').length).to be(3)
    end

    it 'renders resource details', :aggregate_failures do
      within_testid('catalog-resource-item', match: :first) do
        expect(page).to have_content(public_projects_with_components[2].name)
        expect(page).to have_content(public_projects_with_components[2].description)
        expect(page).to have_content(namespace.name)
      end
    end
  end

  shared_examples 'navigates to the details page' do
    context 'when clicking on a resource' do
      before do
        find_by_testid('ci-resource-link', match: :first).click
      end

      it 'navigates to the details page' do
        expect(page).to have_content('Readme')
      end
    end
  end

  context 'when unauthenticated' do
    before do
      visit explore_catalog_index_path
    end

    it_behaves_like 'basic page viewing'
    it_behaves_like 'navigates to the details page'
  end

  context 'when authenticated' do
    before do
      sign_in(user)
      visit explore_catalog_index_path
    end

    it_behaves_like 'basic page viewing'
    it_behaves_like 'navigates to the details page'
  end

  context 'for private catalog resources' do
    let_it_be(:private_project) do
      create(
        :project,
        :catalog_resource_with_components,
        description: 'Our private project',
        namespace: namespace
      )
    end

    let_it_be(:catalog_resource) { create(:ci_catalog_resource, :published, project: private_project) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:browsing_user) { create(:user) }

    context 'when browsing as a developer + member' do
      before_all do
        namespace.add_developer(developer)
      end

      before do
        sign_in(developer)
        visit explore_catalog_index_path
      end

      it 'shows the catalog resource' do
        expect(page).to have_content(private_project.name)
      end
    end

    context 'when browsing as a non-member of the project' do
      before do
        sign_in(browsing_user)
        visit explore_catalog_index_path
      end

      it 'does not show the catalog resource' do
        expect(page).not_to have_content(private_project.name)
      end
    end
  end

  describe 'legal disclaimer' do
    before do
      visit explore_catalog_index_path
    end

    it 'does not show legal disclaimer' do
      expect(page).not_to have_content('This catalog contains third-party content')
      expect(page).not_to have_content(
        'Use of this content is subject to the relevant content provider\'s terms of use.'
      )
      expect(page).not_to have_content('GitLab does not control and has no liability for third-party content')
    end
  end

  describe 'Search and sorting' do
    before do
      visit explore_catalog_index_path
    end

    context 'when searching for a resource' do
      let(:project_name) { public_projects_with_components[0].name }

      before do
        within_testid('catalog-search-bar') do
          find('input').set(project_name)
          click_button 'Search'
        end
        wait_for_requests
      end

      it 'renders only a subset of items' do
        expect(find_all('[data-testid="catalog-resource-item"]').length).to be(1)
        within_testid('catalog-resource-item', match: :first) do
          expect(page).to have_content(project_name)
        end
      end
    end

    context 'when sorting' do
      def select_sort_option(option_text)
        find_by_testid('catalog-sorting-option-button').click
        within('.gl-new-dropdown-contents') do
          find('li', text: option_text).click
        end
        wait_for_requests
      end

      def toggle_sort_direction
        find('.sorting-direction-button').click
        wait_for_requests
      end

      def listed_resource_names
        expect(page).to have_css('[data-testid="catalog-resource-item"]', count: public_projects_with_components.size)
        all_by_testid('catalog-resource-item').map do |item|
          find_by_testid('ci-resource-link', context: item).text
        end
      end

      context 'with Created date' do
        before do
          select_sort_option('Created date')
        end

        it 'lists resources from newest to oldest by default', :aggregate_failures do
          expect(listed_resource_names).to eq(public_projects_with_components.reverse.map(&:name))
        end

        it 'lists resources from oldest to newest when direction is toggled', :aggregate_failures do
          toggle_sort_direction

          expect(listed_resource_names).to eq(public_projects_with_components.map(&:name))
        end
      end

      context 'with Released date' do
        before do
          select_sort_option('Released date')
        end

        it 'lists resources from most to least recently released by default', :aggregate_failures do
          expect(listed_resource_names).to eq(public_projects_with_components.map(&:name))
        end

        it 'lists resources from least to most recently released when direction is toggled', :aggregate_failures do
          toggle_sort_direction

          expect(listed_resource_names).to eq(public_projects_with_components.reverse.map(&:name))
        end
      end
    end
  end
end
