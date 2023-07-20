# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupProjectsFinder do
  include_context 'GroupProjectsFinder context'

  subject { finder.execute }

  describe 'with a group member current user' do
    before do
      root_group.add_maintainer(current_user)
    end

    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }

      context 'with ancestor groups projects' do
        before do
          options[:include_ancestor_groups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
      end

      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
      end
    end

    context "when shared projects are excluded" do
      let(:options) { { exclude_shared: true } }

      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([private_project, public_project, subgroup_project, subgroup_private_project]) }
      end

      context 'with ancestor group projects' do
        before do
          options[:include_ancestor_groups] = true
        end

        it { is_expected.to match_array([private_project, public_project, root_group_public_project, root_group_private_project, root_group_private_project_2]) }
      end

      context 'with ancestor groups and subgroups projects' do
        before do
          options[:include_ancestor_groups] = true
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([private_project, public_project, root_group_public_project, root_group_private_project, root_group_private_project_2, subgroup_private_project, subgroup_project]) }
      end

      context 'without subgroups and ancestor group projects' do
        it { is_expected.to match_array([private_project, public_project]) }
      end

      context 'when user is member only of a subgroup' do
        let(:subgroup_member) { create(:user) }

        context 'with ancestor groups and subgroups projects' do
          before do
            group.add_maintainer(subgroup_member)
            options[:include_ancestor_groups] = true
            options[:include_subgroups] = true
          end

          it 'does not return parent group projects' do
            finder = described_class.new(group: group, current_user: subgroup_member, params: params, options: options)

            projects = finder.execute

            expect(projects).to match_array([private_project, public_project, subgroup_project, subgroup_private_project, root_group_public_project])
          end
        end
      end
    end

    context "owned" do
      before do
        root_group.add_owner(current_user)
      end

      let(:params) { { owned: true } }

      it { is_expected.to match_array([private_project, public_project]) }
    end

    context "all" do
      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project, subgroup_project, subgroup_private_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
      end

      context "with min access level" do
        let!(:shared_project_4) { create(:project, :internal, path: '8') }

        before do
          shared_project_4.project_group_links.create!(group_access: Gitlab::Access::REPORTER, group: group)
        end

        let(:params) { { min_access_level: Gitlab::Access::MAINTAINER } }

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
      end
    end
  end

  describe 'without group member current_user' do
    before do
      shared_project_2.add_maintainer(current_user)
      current_user.reload
    end

    context "only shared" do
      let(:options) { { only_shared: true } }

      context "without external user" do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
      end

      context "with external user" do
        before do
          current_user.update!(external: true)
        end

        it { is_expected.to match_array([shared_project_2, shared_project_1]) }
      end
    end

    context "when shared projects are excluded" do
      let(:options) { { exclude_shared: true } }

      context "without external user" do
        before do
          private_project.add_maintainer(current_user)
          subgroup_private_project.add_maintainer(current_user)
          root_group_private_project.add_maintainer(current_user)
        end

        context 'with subgroups projects' do
          before do
            options[:include_subgroups] = true
          end

          it { is_expected.to match_array([private_project, public_project, subgroup_project, subgroup_private_project]) }
        end

        context 'with ancestor groups projects' do
          before do
            options[:include_ancestor_groups] = true
          end

          it { is_expected.to match_array([private_project, public_project, root_group_public_project, root_group_private_project]) }
        end

        context 'with ancestor groups and subgroups projects' do
          before do
            options[:include_ancestor_groups] = true
            options[:include_subgroups] = true
          end

          it { is_expected.to match_array([private_project, public_project, root_group_private_project, root_group_public_project, subgroup_private_project, subgroup_project]) }
        end

        context 'without subgroups projects' do
          it { is_expected.to match_array([private_project, public_project]) }
        end
      end

      context "with external user" do
        before do
          current_user.update!(external: true)
        end

        context 'with subgroups projects' do
          before do
            options[:include_subgroups] = true
          end

          it { is_expected.to match_array([public_project, subgroup_project]) }
        end

        context 'with ancestor groups projects' do
          before do
            options[:include_ancestor_groups] = true
          end

          it { is_expected.to match_array([public_project, root_group_public_project]) }
        end

        context 'with ancestor groups and subgroups projects' do
          before do
            options[:include_subgroups] = true
            options[:include_ancestor_groups] = true
          end

          it { is_expected.to match_array([public_project, root_group_public_project, subgroup_project]) }
        end

        context 'without subgroups projects' do
          it { is_expected.to eq([public_project]) }
        end
      end
    end

    context "all" do
      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, public_project, subgroup_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, public_project]) }
      end
    end
  end

  describe 'with an admin current user' do
    let(:current_user) { create(:admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      context "only shared" do
        let(:options) { { only_shared: true } }

        it            { is_expected.to contain_exactly(shared_project_3, shared_project_2, shared_project_1) }
      end

      context "when shared projects are excluded" do
        let(:options) { { exclude_shared: true } }

        it            { is_expected.to contain_exactly(private_project, public_project) }
      end

      context "all" do
        it { is_expected.to contain_exactly(shared_project_3, shared_project_2, shared_project_1, private_project, public_project) }
      end
    end

    context 'when admin mode is disabled' do
      context "only shared" do
        let(:options) { { only_shared: true } }

        it            { is_expected.to contain_exactly(shared_project_3, shared_project_1) }
      end

      context "when shared projects are excluded" do
        let(:options) { { exclude_shared: true } }

        it            { is_expected.to contain_exactly(public_project) }
      end

      context "all" do
        it { is_expected.to contain_exactly(shared_project_3, shared_project_1, public_project) }
      end
    end
  end

  describe "no user" do
    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_1]) }
    end

    context "when shared projects are excluded" do
      let(:options) { { exclude_shared: true } }

      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([public_project, subgroup_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to eq([public_project]) }
      end
    end
  end

  describe 'feature availability' do
    let!(:project_with_issues_disabled) { create(:project, :issues_disabled, :internal, path: '9') }
    let!(:project_with_merge_request_disabled) { create(:project, :merge_requests_disabled, :internal, path: '10') }

    before do
      project_with_issues_disabled.project_group_links.create!(group_access: Gitlab::Access::REPORTER, group: group)
      project_with_merge_request_disabled.project_group_links.create!(group_access: Gitlab::Access::REPORTER, group: group)
    end

    context 'without issues and merge request enabled' do
      it { is_expected.to match_array([public_project, shared_project_1, shared_project_3, project_with_issues_disabled, project_with_merge_request_disabled]) }
    end

    context 'with issues enabled' do
      let(:params) { { with_issues_enabled: true } }

      it { is_expected.to match_array([public_project, shared_project_1, shared_project_3, project_with_merge_request_disabled]) }
    end

    context 'with merge request enabled' do
      let(:params) { { with_merge_requests_enabled: true } }

      it { is_expected.to match_array([public_project, shared_project_1, shared_project_3, project_with_issues_disabled]) }
    end

    context 'with issues and merge request enabled' do
      let(:params) { { with_merge_requests_enabled: true, with_issues_enabled: true } }

      it { is_expected.to match_array([public_project, shared_project_1, shared_project_3]) }
    end
  end

  describe 'limiting' do
    context 'without limiting' do
      it 'returns all projects' do
        expect(subject.count).to eq(3)
      end
    end

    context 'with limiting' do
      let(:options) { { limit: 1 } }

      it 'returns only the number of projects specified by the limit' do
        expect(subject.count).to eq(1)
      end
    end
  end
end
