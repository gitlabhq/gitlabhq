# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::FinderHelper do
  describe '#packages_for_project' do
    let_it_be_with_reload(:project1) { create(:project) }
    let_it_be(:package1) { create(:package, project: project1) }
    let_it_be(:package2) { create(:package, :error, project: project1) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:package3) { create(:package, project: project2) }

    let(:finder_class) do
      Class.new do
        include ::Packages::FinderHelper

        def execute(project1)
          packages_for_project(project1)
        end
      end
    end

    let(:finder) { finder_class.new }

    subject { finder.execute(project1) }

    it { is_expected.to eq [package1]}
  end

  describe '#packages_visible_to_user' do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project1) { create(:project, namespace: group) }
    let_it_be(:package1) { create(:package, project: project1) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be_with_reload(:project2) { create(:project, namespace: subgroup) }
    let_it_be(:package2) { create(:package, project: project2) }
    let_it_be(:package3) { create(:package, :error, project: project2) }

    let(:finder_class) do
      Class.new do
        include ::Packages::FinderHelper

        def initialize(user)
          @current_user = user
        end

        def execute(group)
          packages_visible_to_user(@current_user, within_group: group)
        end
      end
    end

    let(:finder) { finder_class.new(user) }

    subject { finder.execute(group) }

    shared_examples 'returning both packages' do
      it { is_expected.to contain_exactly(package1, package2) }
    end

    shared_examples 'returning package1' do
      it { is_expected.to eq [package1]}
    end

    shared_examples 'returning no packages' do
      it { is_expected.to be_empty }
    end

    context 'with a user' do
      let_it_be(:user) { create(:user) }

      where(:group_visibility, :subgroup_visibility, :project2_visibility, :user_role, :shared_example_name) do
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :maintainer | 'returning both packages'
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :developer  | 'returning both packages'
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :guest      | 'returning both packages'
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :anonymous  | 'returning both packages'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :maintainer | 'returning both packages'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :developer  | 'returning both packages'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :guest      | 'returning package1'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :anonymous  | 'returning package1'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both packages'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both packages'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning package1'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :anonymous  | 'returning package1'
        'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both packages'
        'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both packages'
        'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning no packages'
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

  describe '#projects_visible_to_user' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project1) { create(:project, namespace: group) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be_with_reload(:project2) { create(:project, namespace: subgroup) }

    let(:finder_class) do
      Class.new do
        include ::Packages::FinderHelper

        def initialize(user)
          @current_user = user
        end

        def execute(group)
          projects_visible_to_user(@current_user, within_group: group)
        end
      end
    end

    let(:finder) { finder_class.new(user) }

    subject { finder.execute(group) }

    shared_examples 'returning both projects' do
      it { is_expected.to contain_exactly(project1, project2) }
    end

    shared_examples 'returning project1' do
      it { is_expected.to eq [project1]}
    end

    shared_examples 'returning no project' do
      it { is_expected.to be_empty }
    end

    context 'with a user' do
      let_it_be(:user) { create(:user) }

      where(:group_visibility, :subgroup_visibility, :project2_visibility, :user_role, :shared_example_name) do
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :maintainer | 'returning both projects'
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :developer  | 'returning both projects'
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :guest      | 'returning both projects'
        'PUBLIC'  | 'PUBLIC'  | 'PUBLIC'  | :anonymous  | 'returning both projects'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :maintainer | 'returning both projects'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :developer  | 'returning both projects'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :guest      | 'returning project1'
        'PUBLIC'  | 'PUBLIC'  | 'PRIVATE' | :anonymous  | 'returning project1'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both projects'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both projects'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning project1'
        'PUBLIC'  | 'PRIVATE' | 'PRIVATE' | :anonymous  | 'returning project1'
        'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :maintainer | 'returning both projects'
        'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :developer  | 'returning both projects'
        'PRIVATE' | 'PRIVATE' | 'PRIVATE' | :guest      | 'returning no project'
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
end
