# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Infrastructure Registry', feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  context 'when user is not signed in' do
    before do
      visit_group_infrastructure_registry
    end

    it 'returns 200' do
      expect(status_code).to eq(200)
    end

    context 'when there are modules' do
      let_it_be(:terraform_module) do
        create(:terraform_module_package, project: project, created_at: 1.day.ago, version: '1.0.0')
      end

      it 'does not allow you to delete package', :js do
        expect(page).to have_button('Remove package', disabled: true)
      end
    end
  end

  context 'when user is signed in' do
    before do
      sign_in(user)
    end

    context 'when user is not a group member' do
      before do
        visit_group_infrastructure_registry
      end

      it 'returns 200' do
        expect(status_code).to eq(200)
      end

      context 'when there are modules' do
        let_it_be(:terraform_module) do
          create(:terraform_module_package, project: project, created_at: 1.day.ago, version: '1.0.0')
        end

        it 'does not allow you to delete package', :js do
          expect(page).to have_button('Remove package', disabled: true)
        end
      end
    end

    context 'when user is a group member' do
      before_all do
        group.add_maintainer(user)
      end

      context 'when packages registry is not enabled' do
        before do
          stub_config(packages: { enabled: false })
        end

        it 'returns 404' do
          visit_group_infrastructure_registry

          expect(status_code).to eq(404)
        end
      end

      context 'when packages registry is enabled', :js do
        before do
          visit_group_infrastructure_registry
        end

        context 'when there are modules' do
          let_it_be(:terraform_module) do
            create(:terraform_module_package, project: project, created_at: 1.day.ago, version: '1.0.0')
          end

          context 'and there is more than one' do
            let_it_be(:terraform_module2) do
              create(:terraform_module_package, project: project, created_at: 2.days.ago, version: '2.0.0')
            end

            let_it_be(:packages) { [terraform_module, terraform_module2] }

            it_behaves_like 'packages list'
          end

          describe 'details link' do
            it 'navigates to the correct url' do
              page.within(packages_table_selector) do
                click_link terraform_module.name
              end

              expect(page).to have_current_path(project_infrastructure_registry_path(terraform_module.project,
                terraform_module))

              expect(page).to have_css('.packages-app h1[data-testid="page-heading"]', text: terraform_module.name)

              expect(page).to have_content('Provision instructions')
              expect(page).to have_content('Registry setup')
            end
          end

          context 'when deleting a package' do
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
          expect(page).to have_content('You have no Terraform modules in your group')
        end
      end
    end
  end

  def visit_group_infrastructure_registry
    visit group_infrastructure_registry_index_path(group)
  end
end
