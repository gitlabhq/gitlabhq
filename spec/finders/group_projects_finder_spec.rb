require 'spec_helper'

describe GroupProjectsFinder do
  let(:group) { create(:group) }
  let(:subgroup) { create(:group, parent: group) }
  let(:current_user) { create(:user) }
  let(:options) { {} }

  let(:finder) { described_class.new(group: group, current_user: current_user, options: options) }

  let!(:public_project) { create(:project, :public, group: group, path: '1') }
  let!(:private_project) { create(:project, :private, group: group, path: '2') }
  let!(:shared_project_1) { create(:project, :public, path: '3') }
  let!(:shared_project_2) { create(:project, :private, path: '4') }
  let!(:shared_project_3) { create(:project, :internal, path: '5') }
  let!(:subgroup_project) { create(:project, :public, path: '6', group: subgroup) }
  let!(:subgroup_private_project) { create(:project, :private, path: '7', group: subgroup) }

  before do
    shared_project_1.project_group_links.create(group_access: Gitlab::Access::MASTER, group: group)
    shared_project_2.project_group_links.create(group_access: Gitlab::Access::MASTER, group: group)
    shared_project_3.project_group_links.create(group_access: Gitlab::Access::MASTER, group: group)
  end

  subject { finder.execute }

  describe 'with a group member current user' do
    before do
      group.add_master(current_user)
    end

    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      context 'with subgroups projects', :nested_groups do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([private_project, public_project, subgroup_project, subgroup_private_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([private_project, public_project]) }
      end
    end

    context "all" do
      context 'with subgroups projects', :nested_groups do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project, subgroup_project, subgroup_private_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
      end
    end
  end

  describe 'without group member current_user' do
    before do
      shared_project_2.add_master(current_user)
      current_user.reload
    end

    context "only shared" do
      let(:options) { { only_shared: true } }

      context "without external user" do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
      end

      context "with external user" do
        before do
          current_user.update_attributes(external: true)
        end

        it { is_expected.to match_array([shared_project_2, shared_project_1]) }
      end
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      context "without external user" do
        before do
          private_project.add_master(current_user)
          subgroup_private_project.add_master(current_user)
        end

        context 'with subgroups projects', :nested_groups do
          before do
            options[:include_subgroups] = true
          end

          it { is_expected.to match_array([private_project, public_project, subgroup_project, subgroup_private_project]) }
        end

        context 'without subgroups projects' do
          it { is_expected.to match_array([private_project, public_project]) }
        end
      end

      context "with external user" do
        before do
          current_user.update_attributes(external: true)
        end

        context 'with subgroups projects', :nested_groups do
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

    context "all" do
      context 'with subgroups projects', :nested_groups do
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

  describe "no user" do
    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      context 'with subgroups projects', :nested_groups do
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
end
