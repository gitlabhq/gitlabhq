# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Packages' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    sign_in(user)
    group.add_maintainer(user)
  end

  context 'when feature is not available' do
    context 'packages feature is disabled by config' do
      before do
        allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
      end

      it 'gives 404' do
        visit_group_packages

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when feature is available', :js do
    before do
      visit_group_packages
    end

    it 'sidebar menu is open' do
      sidebar = find('.nav-sidebar')
      expect(sidebar).to have_link _('Package Registry')
    end

    context 'when there are packages' do
      let_it_be(:second_project) { create(:project, name: 'second-project', group: group) }
      let_it_be(:npm_package) { create(:npm_package, project: project, name: 'zzz', created_at: 1.day.ago, version: '1.0.0') }
      let_it_be(:maven_package) { create(:maven_package, project: second_project, name: 'aaa', created_at: 2.days.ago, version: '2.0.0') }
      let_it_be(:packages) { [npm_package, maven_package] }

      it_behaves_like 'packages list', check_project_name: true

      context 'when package_details_apollo feature flag is off' do
        before do
          stub_feature_flags(package_details_apollo: false)
        end

        it_behaves_like 'package details link'
      end

      it 'allows you to navigate to the project page' do
        find('[data-testid="root-link"]', text: project.name).click

        expect(page).to have_current_path(project_path(project))
        expect(page).to have_content(project.name)
      end

      context 'sorting' do
        it_behaves_like 'shared package sorting' do
          let_it_be(:package_one) { maven_package }
          let_it_be(:package_two) { npm_package }
        end

        it_behaves_like 'correctly sorted packages list', 'Project' do
          let(:packages) { [maven_package, npm_package] }
        end

        it_behaves_like 'correctly sorted packages list', 'Project', ascending: true do
          let(:packages) { [npm_package, maven_package] }
        end
      end
    end

    it_behaves_like 'when there are no packages'
  end

  def visit_group_packages
    visit group_packages_path(group)
  end
end
