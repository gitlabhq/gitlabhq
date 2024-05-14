# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI/CD Catalog releases', :js, feature_category: :pipeline_composition, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/432824' do
  let_it_be(:tag_name) { 'catalog_release_tag' }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:group, owners: user) }
  let_it_be_with_reload(:project) do
    create(
      :project,
      :catalog_resource_with_components,
      description: 'Brand new thing',
      namespace: namespace
    )
  end

  let_it_be(:draft_catalog_resource) do
    create(:ci_catalog_resource, project: project)
  end

  before do
    sign_in(user)
  end

  context 'when a resource is in draft' do
    it 'does not render it in the Catalog', :aggregate_failures do
      visit explore_catalog_index_path

      expect(find_all('[data-testid="catalog-resource-item"]').length).to be(0)
      expect(page).not_to have_content(project.name)
    end
  end

  describe 'when releasing a Catalog resource' do
    before do
      visit new_project_tag_path(project)
      fill_in('tag_name', with: tag_name)
      click_button 'Create tag'

      # Click on the option to create release from the tags page
      find('a', text: 'Create release').click

      # Makes the actual release
      click_button 'Create release'
      wait_for_requests

      visit explore_catalog_index_path
    end

    it 'appears in the CI/CD Catalog', :aggregate_failures do
      expect(find_all('[data-testid="catalog-resource-item"]').length).to be(1)
      within_testid('catalog-list-container') do
        expect(page).to have_content(project.name)
        expect(page).to have_content(tag_name)
        expect(page).to have_content("Released")
      end

      visit explore_catalog_path(draft_catalog_resource)

      expect(page).to have_content("Last release at")
      expect(page).to have_content(tag_name)
    end
  end

  describe 'when a resource has multiple releases' do
    let_it_be(:project_with_components) do
      create(
        :project,
        :catalog_resource_with_components,
        description: 'Brand new thing',
        namespace: namespace
      )
    end

    let_it_be(:ci_resource) do
      create(:ci_catalog_resource, :published, project: project_with_components)
    end

    let_it_be(:old_tag_name) { 'v0.5' }
    let_it_be(:new_tag_name) { 'v1.0' }

    let_it_be(:release_1) do
      create(:release, :with_catalog_resource_version, project: project_with_components, tag: old_tag_name,
        author: user)
    end

    let_it_be(:release_2) do
      create(:release, :with_catalog_resource_version, project: project_with_components, tag: new_tag_name,
        author: user)
    end

    it 'renders the last version on the catalog list item' do
      visit explore_catalog_index_path

      expect(page).to have_content(release_2.tag)
      expect(page).not_to have_content(release_1.tag)
    end

    it 'renders the last version on the catalog details page' do
      visit explore_catalog_path(ci_resource)

      expect(page).to have_content(release_2.tag)
      expect(page).not_to have_content(release_1.tag)
    end
  end
end
