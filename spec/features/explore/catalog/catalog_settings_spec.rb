# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI/CD Catalog settings', :js, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:group) }
  let_it_be_with_reload(:new_project) { create(:project, :repository, namespace: namespace) }

  context 'when user is not the owner' do
    before do
      sign_in(user)
      visit edit_project_path(new_project)
      wait_for_requests
    end

    it 'does not show the CI/CD toggle settings' do
      expect(page).not_to have_content('CI/CD Catalog resource')
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
      visit edit_project_path(new_project)
      wait_for_requests

      expect(page).to have_content('CI/CD Catalog resource')
    end

    describe 'when setting a project as a Catalog resource' do
      before do
        visit project_path(new_project)
        wait_for_requests
      end

      it 'adds the project to the CI/CD Catalog' do
        expect(page).not_to have_content('CI/CD catalog resource')

        visit edit_project_path(new_project)

        find('[data-testid="catalog-resource-toggle"] button').click

        visit project_path(new_project)

        expect(page).to have_content('CI/CD catalog resource')
      end
    end

    describe 'when unlisting a project from the CI/CD Catalog' do
      before do
        create(:ci_catalog_resource, project: new_project, state: :published)
        visit project_path(new_project)
        wait_for_requests
      end

      it 'removes the project to the CI/CD Catalog' do
        expect(page).to have_content('CI/CD catalog resource')

        visit edit_project_path(new_project)

        find('[data-testid="catalog-resource-toggle"] button').click
        click_button 'Remove from the CI/CD catalog'

        visit project_path(new_project)

        expect(page).not_to have_content('CI/CD catalog resource')
      end
    end
  end
end
