# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Infrastructure Registry', feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'when packages registry is not enabled' do
    before do
      stub_config(packages: { enabled: false })
    end

    it 'gives 404' do
      visit_project_infrastructure_registry

      expect(status_code).to eq(404)
    end
  end

  context 'when packages registry is enabled', :js do
    before do
      visit_project_infrastructure_registry
    end

    context 'when there are modules' do
      let_it_be(:terraform_module) { create(:terraform_module_package, project: project, created_at: 1.day.ago, version: '1.0.0') }
      let_it_be(:terraform_module2) { create(:terraform_module_package, project: project, created_at: 2.days.ago, version: '2.0.0') }
      let_it_be(:packages) { [terraform_module, terraform_module2] }

      it_behaves_like 'packages list'

      context 'details link' do
        it 'navigates to the correct url' do
          page.within(packages_table_selector) do
            click_link terraform_module.name
          end

          expect(page).to have_current_path(project_infrastructure_registry_path(terraform_module.project, terraform_module))

          expect(page).to have_css('.packages-app h1[data-testid="page-heading"]', text: terraform_module.name)

          expect(page).to have_content('Provision instructions')
          expect(page).to have_content('Registry setup')
        end
      end

      context 'deleting a package' do
        let_it_be(:project) { create(:project) }
        let_it_be(:terraform_module) { create(:terraform_module_package, project: project) }

        it 'allows you to delete a module', :aggregate_failures do
          # this is still using the package copy in the UI too
          click_button('Remove package')
          click_button('Permanently delete')

          expect(page).to have_content 'Package deleted successfully'
          expect(page).not_to have_content(terraform_module.name)
        end
      end
    end

    it 'displays the empty message' do
      expect(page).to have_content('You have no Terraform modules in your project')
    end
  end

  def visit_project_infrastructure_registry
    visit project_infrastructure_registry_index_path(project)
  end
end
