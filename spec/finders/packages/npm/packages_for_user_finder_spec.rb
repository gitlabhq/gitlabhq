# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::PackagesForUserFinder, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:package) { create(:npm_package, project: project) }
  let_it_be(:package_name) { package.name }
  let_it_be(:package_with_diff_name) { create(:npm_package, project: project) }
  let_it_be(:package_with_diff_project) { create(:npm_package, name: package_name, project: project2) }
  let_it_be(:maven_package) { create(:maven_package, name: package_name, project: project) }

  let(:finder) { described_class.new(user, project_or_group, package_name: package_name) }

  describe '#execute' do
    subject { finder.execute }

    shared_examples 'searches for packages' do
      it { is_expected.to contain_exactly(package) }
    end

    context 'with a project' do
      let(:project_or_group) { project }

      it_behaves_like 'searches for packages'
      it_behaves_like 'avoids N+1 database queries in the package registry'
    end

    context 'with a group' do
      let(:project_or_group) { group }

      before_all do
        project.add_reporter(user)
      end

      it_behaves_like 'searches for packages'
      it_behaves_like 'avoids N+1 database queries in the package registry'

      context 'when an user is a reporter of both projects' do
        before_all do
          project2.add_reporter(user)
        end

        it { is_expected.to contain_exactly(package, package_with_diff_project) }

        context 'when the second project has the package registry disabled' do
          before_all do
            project.reload.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            project2.reload.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC,
              package_registry_access_level: 'disabled', packages_enabled: false)
          end

          it_behaves_like 'searches for packages'
        end
      end
    end
  end
end
