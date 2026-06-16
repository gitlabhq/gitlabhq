# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI/CD Catalog settings', :js, feature_category: :pipeline_composition do
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:group) }
  let_it_be_with_reload(:project_with_ci_components) do
    create(
      :project,
      :catalog_resource_with_components,
      description: "catalog resource description",
      namespace: namespace
    )
  end

  let_it_be(:catalog_resource, freeze: false) { create(:ci_catalog_resource, project: project_with_ci_components) }

  context 'when user is not the owner' do
    before_all do
      namespace.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    it 'does not show the CI/CD toggle settings' do
      expect(page).not_to have_content('CI/CD Catalog project')
    end
  end

  context 'when user is the owner' do
    before_all do
      namespace.add_owner(user)
    end

    before do
      sign_in(user)
    end

    it 'shows the CI/CD toggle settings' do
      visit edit_project_path(project_with_ci_components)
      wait_for_requests

      expect(page).to have_content('CI/CD Catalog project')
    end

    context 'when a project is not a Catalog resource' do
      let_it_be(:plain_project, freeze: false) { create(:project, namespace: namespace) }

      before do
        visit project_path(plain_project)
      end

      it 'does not render the CI/CD resource badge' do
        expect(page).to have_content(plain_project.name)
        expect(page).not_to have_content('CI/CD catalog resource')
      end
    end

    describe 'when listing a project as a Catalog resource' do
      let_it_be(:tag_name) { 'v0.1.0' }

      before do
        visit edit_project_path(project_with_ci_components)
        find('[data-testid="catalog-resource-toggle"] button').click
        wait_for_requests
      end

      it 'marks the project as a CI/CD Catalog' do
        visit project_path(project_with_ci_components)

        expect(page).to have_content('CI/CD Catalog (unpublished)')
      end

      context 'and there are no releases' do
        before do
          visit explore_catalog_index_path
        end

        it 'does not add the resource to the catalog', :aggregate_failures do
          expect(page).to have_content("CI/CD Catalog")
          expect(find_all('[data-testid="catalog-resource-item"]').length).to be(0)
        end
      end

      context 'and there is a release' do
        before do
          release = create(:release, tag: tag_name, author: user, project: project_with_ci_components)
          create(:ci_catalog_resource_version,
            catalog_resource: catalog_resource,
            project: project_with_ci_components,
            release: release,
            semver: tag_name)
          # This call to `publish` is necessary to simulate what creating a release would really do
          catalog_resource.publish!
          visit explore_catalog_index_path
        end

        it 'adds the resource to the catalog', :aggregate_failures do
          expect(page).to have_content("CI/CD Catalog")
          expect(find_all('[data-testid="catalog-resource-item"]').length).to be(1)
          expect(page).to have_content(tag_name)
        end
      end
    end

    describe 'when unlisting a project from the CI/CD Catalog' do
      before do
        release = create(:release, tag: 'v0.1.0', author: user, project: project_with_ci_components)
        create(:ci_catalog_resource_version,
          catalog_resource: catalog_resource,
          project: project_with_ci_components,
          release: release,
          semver: 'v0.1.0')
        catalog_resource.publish!

        visit edit_project_path(project_with_ci_components)

        find('[data-testid="catalog-resource-toggle"] button').click
        click_button 'Remove from the CI/CD catalog'
      end

      it 'removes the CI/CD Catalog tag on the project' do
        visit project_path(project_with_ci_components)

        expect(page).not_to have_content('CI/CD catalog resource')
      end

      it 'removes the resource from the catalog' do
        visit explore_catalog_index_path

        expect(page).not_to have_content(project_with_ci_components.name)
        expect(find_all('[data-testid="catalog-resource-item"]').length).to be(0)
      end

      it 'does not destroy existing releases' do
        visit project_releases_path(project_with_ci_components)

        expect(page).to have_content(project_with_ci_components.releases.last.name)
      end
    end
  end
end
