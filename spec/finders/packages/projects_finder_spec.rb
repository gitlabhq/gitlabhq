# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::ProjectsFinder, feature_category: :package_registry do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, namespace: group) }
    let_it_be_with_reload(:project2) { create(:project, :public, namespace: group) }
    let_it_be(:project3) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    let(:params) { {} }

    subject { described_class.new(current_user:, group:, params:).execute }

    shared_context 'with package registry enabled' do
      let(:params) { super().merge(with_package_registry_enabled: true) }

      before_all do
        project.update!(package_registry_access_level: 'disabled', packages_enabled: false)
      end
    end

    context 'with a user' do
      before_all do
        project.add_guest(current_user)
      end

      it { is_expected.to contain_exactly(project, project2) }

      context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        it { is_expected.to contain_exactly(project2) }

        context 'with a reporter role' do
          before_all do
            project.add_reporter(current_user)
          end

          it { is_expected.to contain_exactly(project, project2) }
        end
      end

      context 'when subgroup has projects' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:project3) { create(:project, namespace: subgroup) }

        before_all do
          project3.add_guest(current_user)
        end

        it { is_expected.to contain_exactly(project, project2, project3) }

        context 'when excluding subgroups' do
          let(:params) { { exclude_subgroups: true } }

          it { is_expected.to contain_exactly(project, project2) }
        end
      end

      context 'with package registry enabled' do
        include_context 'with package registry enabled'

        it { is_expected.to contain_exactly(project2) }
      end

      context 'with public package registry' do
        let(:params) { super().merge(within_public_package_registry: true) }

        before_all do
          project2.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          project2.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
        end

        it { is_expected.to contain_exactly(project, project2) }
      end

      context 'with projects with repository feature' do
        before_all do
          project2.project_feature.update!(
            repository_access_level: ProjectFeature::DISABLED,
            merge_requests_access_level: ProjectFeature::DISABLED,
            builds_access_level: ProjectFeature::DISABLED
          )
        end

        it { is_expected.to contain_exactly(project) }
      end

      context 'without a group' do
        let(:group) { nil }

        it { is_expected.to be_empty }
      end
    end

    context 'with a deploy token' do
      context 'with a group deploy token' do
        let_it_be(:current_user) do
          create(:deploy_token, :group, read_package_registry: true, groups: [group])
        end

        it { is_expected.to contain_exactly(project, project2) }

        context 'with package registry enabled' do
          include_context 'with package registry enabled'

          it { is_expected.to contain_exactly(project2) }
        end

        context 'without a group' do
          let(:group) { nil }

          it { is_expected.to contain_exactly(project, project2) }
        end
      end

      context 'with a project deploy token' do
        let_it_be(:current_user) do
          create(:deploy_token, read_package_registry: true, projects: [project])
        end

        it { is_expected.to contain_exactly(project) }

        context 'with package registry enabled' do
          include_context 'with package registry enabled'

          it { is_expected.to be_empty }
        end

        context 'without a group' do
          let(:group) { nil }

          it { is_expected.to contain_exactly(project) }
        end
      end
    end
  end
end
