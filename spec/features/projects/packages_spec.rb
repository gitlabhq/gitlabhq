# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Packages', feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'when feature is not available' do
    context 'packages feature is disabled by config' do
      before do
        allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
      end

      it 'gives 404' do
        visit_project_packages

        expect(status_code).to eq(404)
      end
    end
  end

  context 'when feature is available', :js do
    before do
      visit_project_packages
    end

    context 'when there are packages' do
      let_it_be(:npm_package) { create(:npm_package, :with_build, project: project, name: 'zzz', created_at: 1.day.ago, version: '1.0.0') }
      let_it_be(:maven_package) { create(:maven_package, project: project, name: 'aaa', created_at: 2.days.ago, version: '2.0.0') }
      let_it_be(:packages) { [npm_package, maven_package] }

      let(:package) { packages.first }
      let(:package_details_path) { project_package_path(project, package) }

      it_behaves_like 'packages list'

      it_behaves_like 'pipelines on packages list'

      it_behaves_like 'package details link'

      context 'deleting a package' do
        let_it_be(:project) { create(:project) }
        let_it_be(:package) { create(:generic_package, project: project) }

        it 'allows you to delete a package' do
          find_by_testid('delete-dropdown').click
          find_by_testid('action-delete').click
          click_button('Permanently delete')

          expect(page).to have_content 'Package deleted successfully'
          expect(page).not_to have_content(package.name)
        end
      end

      it_behaves_like 'shared package sorting' do
        let_it_be(:package_one) { maven_package }
        let_it_be(:package_two) { npm_package }
      end

      context 'filtering' do
        it_behaves_like 'shared package filtering' do
          let_it_be(:package_one) { maven_package }
          let_it_be(:package_two) { npm_package }
        end
      end
    end

    it_behaves_like 'when there are no packages'
  end

  def visit_project_packages
    visit project_packages_path(project)
  end
end
