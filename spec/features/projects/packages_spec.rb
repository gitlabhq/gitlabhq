# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Packages' do
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
      let_it_be(:npm_package) { create(:npm_package, project: project, name: 'zzz', created_at: 1.day.ago, version: '1.0.0') }
      let_it_be(:maven_package) { create(:maven_package, project: project, name: 'aaa', created_at: 2.days.ago, version: '2.0.0') }
      let_it_be(:packages) { [npm_package, maven_package] }

      it_behaves_like 'packages list'

      context 'when package_details_apollo feature flag is off' do
        before do
          stub_feature_flags(package_details_apollo: false)
        end

        it_behaves_like 'package details link'
      end

      context 'deleting a package' do
        let_it_be(:project) { create(:project) }
        let_it_be(:package) { create(:package, project: project) }

        it 'allows you to delete a package' do
          first('[title="Remove package"]').click
          click_button('Delete package')

          expect(page).to have_content 'Package deleted successfully'
          expect(page).not_to have_content(package.name)
        end
      end

      it_behaves_like 'shared package sorting' do
        let_it_be(:package_one) { maven_package }
        let_it_be(:package_two) { npm_package }
      end
    end

    it_behaves_like 'when there are no packages'
  end

  def visit_project_packages
    visit project_packages_path(project)
  end
end
