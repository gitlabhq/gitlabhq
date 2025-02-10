# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::FinderHelper, feature_category: :package_registry do
  let_it_be(:finder_class) do
    Class.new do
      include ::Packages::FinderHelper

      def method_missing(method_name, *args, **kwargs)
        send(method_name, *args, **kwargs)
      end

      def respond_to_missing?
        true
      end

      def packages_class
        ::Packages::Generic::Package
      end
    end
  end

  let_it_be(:finder) { finder_class.new }

  describe '#packages_for_project' do
    let_it_be_with_reload(:project1) { create(:project) }
    let_it_be(:package1) { create(:generic_package, project: project1) }
    let_it_be(:package2) { create(:generic_package, :error, project: project1) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:package3) { create(:generic_package, project: project2) }

    subject { finder.packages_for_project(project1) }

    it { is_expected.to eq [package1] }
  end

  describe '#packages_for' do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:project2) { create(:project, namespace: subgroup) }
    let_it_be(:package1) { create(:generic_package, project: project) }
    let_it_be(:package2) { create(:generic_package, project: project2) }
    let_it_be(:package3) { create(:generic_package, :error, project: project2) }

    subject { finder.packages_for(user, within_group: group) }

    shared_examples 'returning both packages' do
      it { is_expected.to contain_exactly(package1, package2) }
    end

    shared_examples 'returning no packages' do
      it { is_expected.to be_empty }
    end

    shared_examples 'returning package2' do
      it { is_expected.to contain_exactly(package2) }
    end

    context 'with an user' do
      let_it_be(:user) { create(:user) }

      where(:group_visibility, :subgroup_visibility, :shared_example_name) do
        'public'  | 'public'  | 'returning both packages'
        # All packages are returned because of the parent group visibility set to `public`
        # and all users will have `read_group` permission.
        'public'  | 'private' | 'returning both packages'
        # No packages are returned because of the parent group visibility set to `private`
        # and non-members won't have `read_group` permission.
        'private' | 'private' | 'returning no packages'
      end

      with_them do
        before do
          subgroup.update!(visibility: subgroup_visibility)
          group.update!(visibility: group_visibility)
        end

        it_behaves_like params[:shared_example_name]
      end

      context 'without a group' do
        let(:group) { nil }

        it_behaves_like 'returning no packages'
      end

      context 'with a subgroup' do
        let(:group) { subgroup }

        it_behaves_like 'returning package2'
      end
    end

    context 'with a deploy token' do
      let_it_be(:user) { create(:deploy_token, :group, read_package_registry: true) }
      let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: user, group: group) }

      where(:group_visibility, :subgroup_visibility, :shared_example_name) do
        'public'  | 'public'  | 'returning both packages'
        'public'  | 'private' | 'returning both packages'
        'private' | 'private' | 'returning both packages'
      end

      with_them do
        before do
          subgroup.update!(visibility: subgroup_visibility)
          group.update!(visibility: group_visibility)
        end

        it_behaves_like params[:shared_example_name]
      end

      context 'without a group' do
        let(:group) { nil }

        it_behaves_like 'returning no packages'
      end

      context 'with a subgroup' do
        let(:group) { subgroup }

        it_behaves_like 'returning both packages'
      end
    end
  end

  context 'for packages visible to user' do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project1) { create(:project, namespace: group) }
    let_it_be(:package1) { create(:generic_package, project: project1) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be_with_reload(:project2) { create(:project, namespace: subgroup) }
    let_it_be(:package2) { create(:generic_package, project: project2) }
    let_it_be(:package3) { create(:generic_package, :error, project: project2) }

    shared_examples 'returning both packages' do
      it { is_expected.to contain_exactly(package1, package2) }
    end

    shared_examples 'returning package1' do
      it { is_expected.to eq [package1] }
    end

    shared_examples 'returning package2' do
      it { is_expected.to eq [package2] }
    end

    shared_examples 'returning no packages' do
      it { is_expected.to be_empty }
    end

    describe '#packages_visible_to_user' do
      subject { finder.packages_visible_to_user(user, within_group: group) }

      context 'with a user' do
        let_it_be(:user) { create(:user) }

        where(:group_visibility, :subgroup_visibility, :project2_visibility, :user_role, :shared_example_name) do
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :maintainer | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :developer  | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :guest      | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :anonymous  | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :maintainer | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :developer  | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :guest      | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :anonymous  | 'returning package1'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both packages'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both packages'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning both packages'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :anonymous  | 'returning package1'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both packages'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both packages'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning both packages'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :anonymous  | 'returning no packages'
        end

        with_them do
          before do
            unless user_role == :anonymous
              group.send("add_#{user_role}", user)
              subgroup.send("add_#{user_role}", user)
              project1.send("add_#{user_role}", user)
              project2.send("add_#{user_role}", user)
            end

            project2.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project2_visibility, false))
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            project1.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
          end

          it_behaves_like params[:shared_example_name]
        end

        context 'when the second project has the package registry disabled' do
          before do
            project1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            project2.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC,
              package_registry_access_level: 'disabled', packages_enabled: false)
          end

          it_behaves_like 'returning both packages'

          context 'with with_package_registry_enabled set to true' do
            subject do
              finder.packages_visible_to_user(user, within_group: group, with_package_registry_enabled: true)
            end

            it_behaves_like 'returning package1'
          end
        end

        context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
          before_all do
            group.add_guest(user)
            subgroup.add_guest(user)
            project1.add_guest(user)
            project2.add_guest(user)
          end

          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
            project2.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project2_visibility, false))
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            project1.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
          end

          where(:group_visibility, :subgroup_visibility, :project2_visibility, :shared_example_name) do
            'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | 'returning package1'
            'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | 'returning package1'
            'PRIVATE' | 'PRIVATE' | 'PRIVATE' | 'returning no packages'
          end

          with_them do
            it_behaves_like params[:shared_example_name]
          end
        end
      end

      context 'with a group deploy token' do
        let_it_be(:user) { create(:deploy_token, :group, read_package_registry: true) }
        let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: user, group: group) }

        where(:group_visibility, :subgroup_visibility, :project2_visibility, :shared_example_name) do
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | 'returning both packages'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | 'returning both packages'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | 'returning both packages'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | 'returning both packages'
        end

        with_them do
          before do
            project2.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project2_visibility, false))
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            project1.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
          end

          it_behaves_like params[:shared_example_name]
        end
      end
    end

    describe '#packages_visible_to_user_including_public_registries' do
      subject { finder.packages_visible_to_user_including_public_registries(user, within_group: group) }

      let(:user) { nil }

      before do
        [subgroup, group, project1, project2].each do |entity|
          entity.update!(visibility_level: Gitlab::VisibilityLevel.const_get(:PRIVATE, false))
        end
        project1.project_feature.update!(package_registry_access_level: project1_package_registry_access_level)
        project2.project_feature.update!(package_registry_access_level: project2_package_registry_access_level)
      end

      where(:project1_package_registry_access_level, :project2_package_registry_access_level, :shared_example_name) do
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::PUBLIC   | 'returning both packages'
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::PRIVATE  | 'returning package1'
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::DISABLED | 'returning package1'
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::ENABLED  | 'returning package1'
        ::ProjectFeature::PRIVATE  | ::ProjectFeature::PUBLIC   | 'returning package2'
        ::ProjectFeature::DISABLED | ::ProjectFeature::PUBLIC   | 'returning package2'
        ::ProjectFeature::ENABLED  | ::ProjectFeature::PUBLIC   | 'returning package2'
        ::ProjectFeature::PRIVATE  | ::ProjectFeature::PRIVATE  | 'returning no packages'
      end

      with_them do
        it_behaves_like params[:shared_example_name]
      end
    end
  end

  context 'for projecs visibile to user' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project1) { create(:project, namespace: group) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be_with_reload(:project2) { create(:project, namespace: subgroup) }

    shared_examples 'returning both projects' do
      it { is_expected.to contain_exactly(project1, project2) }
    end

    shared_examples 'returning project1' do
      it { is_expected.to eq [project1] }
    end

    shared_examples 'returning project2' do
      it { is_expected.to eq [project2] }
    end

    shared_examples 'returning no project' do
      it { is_expected.to be_empty }
    end

    describe '#projects_visible_to_user' do
      subject { finder.projects_visible_to_user(user, within_group: group) }

      context 'with a user' do
        where(:group_visibility, :subgroup_visibility, :project2_visibility, :user_role, :shared_example_name) do
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :maintainer | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :developer  | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :guest      | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :anonymous  | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :maintainer | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :developer  | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :guest      | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :anonymous  | 'returning project1'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both projects'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both projects'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning both projects'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :anonymous  | 'returning project1'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both projects'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both projects'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning both projects'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :anonymous  | 'returning no project'
        end

        with_them do
          before do
            unless user_role == :anonymous
              group.send("add_#{user_role}", user)
              subgroup.send("add_#{user_role}", user)
              project1.send("add_#{user_role}", user)
              project2.send("add_#{user_role}", user)
            end

            project2.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project2_visibility, false))
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            project1.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
          end

          it_behaves_like params[:shared_example_name]
        end
      end

      context 'with a group deploy token' do
        let_it_be(:user) { create(:deploy_token, :group, read_package_registry: true) }
        let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: user, group: group) }

        where(:group_visibility, :subgroup_visibility, :project2_visibility, :shared_example_name) do
          'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | 'returning both projects'
          'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | 'returning both projects'
          'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | 'returning both projects'
          'PRIVATE' | 'PRIVATE' | 'PRIVATE' | 'returning both projects'
        end

        with_them do
          before do
            project2.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project2_visibility, false))
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            project1.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
          end

          it_behaves_like params[:shared_example_name]
        end
      end
    end

    describe '#projects_visible_to_user_including_public_registries' do
      subject { finder.projects_visible_to_user_including_public_registries(user, within_group: group) }

      before do
        [subgroup, group, project1, project2].each do |entity|
          entity.update!(visibility_level: Gitlab::VisibilityLevel.const_get(:PRIVATE, false))
        end
        project1.project_feature.update!(package_registry_access_level: project1_package_registry_access_level)
        project2.project_feature.update!(package_registry_access_level: project2_package_registry_access_level)
      end

      where(:project1_package_registry_access_level, :project2_package_registry_access_level, :shared_example_name) do
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::PUBLIC   | 'returning both projects'
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::PRIVATE  | 'returning project1'
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::DISABLED | 'returning project1'
        ::ProjectFeature::PUBLIC   | ::ProjectFeature::ENABLED  | 'returning project1'
        ::ProjectFeature::PRIVATE  | ::ProjectFeature::PUBLIC   | 'returning project2'
        ::ProjectFeature::DISABLED | ::ProjectFeature::PUBLIC   | 'returning project2'
        ::ProjectFeature::ENABLED  | ::ProjectFeature::PUBLIC   | 'returning project2'
        ::ProjectFeature::PRIVATE  | ::ProjectFeature::PRIVATE  | 'returning no project'
      end

      with_them do
        it_behaves_like params[:shared_example_name]
      end
    end
  end
end
