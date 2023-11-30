# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI/CD Catalog', :js, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }

  before_all do
    namespace.add_developer(user)
  end

  before do
    sign_in(user)
  end

  describe 'GET explore/catalog' do
    let_it_be(:project) { create(:project, :repository, namespace: namespace) }

    let_it_be(:ci_resource_projects) do
      create_list(
        :project,
        3,
        :repository,
        description: 'A simple component',
        namespace: namespace
      )
    end

    let_it_be(:ci_catalog_resources) do
      ci_resource_projects.map do |current_project|
        create(:ci_catalog_resource, :published, project: current_project)
      end
    end

    before do
      visit explore_catalog_index_path
      wait_for_requests
    end

    it 'shows CI Catalog title and description', :aggregate_failures do
      expect(page).to have_content('CI/CD Catalog')
      expect(page).to have_content(
        'Discover CI/CD components that can improve your pipeline with additional functionality'
      )
    end

    it 'renders CI Catalog resources list' do
      expect(find_all('[data-testid="catalog-resource-item"]').length).to be(3)
    end

    context 'when searching for a resource' do
      let(:project_name) { ci_resource_projects[0].name }

      before do
        find('input[data-testid="catalog-search-bar"]').send_keys project_name
        find('input[data-testid="catalog-search-bar"]').send_keys :enter
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
      context 'with the creation date option' do
        it 'sorts resources from last to first by default' do
          expect(find_all('[data-testid="catalog-resource-item"]').length).to be(3)
          expect(find_all('[data-testid="catalog-resource-item"]')[0]).to have_content(ci_resource_projects[2].name)
          expect(find_all('[data-testid="catalog-resource-item"]')[2]).to have_content(ci_resource_projects[0].name)
        end

        context 'when changing the sort direction' do
          before do
            find('.sorting-direction-button').click
            wait_for_requests
          end

          it 'sorts resources from first to last' do
            expect(find_all('[data-testid="catalog-resource-item"]').length).to be(3)
            expect(find_all('[data-testid="catalog-resource-item"]')[0]).to have_content(ci_resource_projects[0].name)
            expect(find_all('[data-testid="catalog-resource-item"]')[2]).to have_content(ci_resource_projects[2].name)
          end
        end
      end
    end

    context 'for a single CI/CD catalog resource' do
      it 'renders resource details', :aggregate_failures do
        within_testid('catalog-resource-item', match: :first) do
          expect(page).to have_content(ci_resource_projects[2].name)
          expect(page).to have_content(ci_resource_projects[2].description)
          expect(page).to have_content(namespace.name)
        end
      end

      context 'when clicked' do
        before do
          find_by_testid('ci-resource-link', match: :first).click
        end

        it 'navigates to the details page' do
          expect(page).to have_content('Go to the project')
        end
      end
    end
  end

  describe 'GET explore/catalog/:id' do
    let_it_be(:project) { create(:project, :repository, namespace: namespace) }

    before do
      visit explore_catalog_path(id: new_ci_resource["id"])
    end

    context 'when the resource is published' do
      let_it_be(:new_ci_resource) { create(:ci_catalog_resource, :published, project: project) }

      it 'navigates to the details page' do
        expect(page).to have_content('Go to the project')
      end
    end

    context 'when the resource is not published' do
      let_it_be(:new_ci_resource) { create(:ci_catalog_resource, project: project, state: :draft) }

      it 'returns a 404' do
        expect(page).to have_title('Not Found')
        expect(page).to have_content('Page Not Found')
      end
    end
  end
end
