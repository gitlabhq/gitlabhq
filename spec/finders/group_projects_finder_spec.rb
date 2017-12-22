require 'spec_helper'

describe GroupProjectsFinder do
  let(:group) { create(:group) }
  let(:current_user) { create(:user) }
  let(:options) { {} }

  let(:finder) { described_class.new(group: group, current_user: current_user, options: options) }

  let!(:public_project) { create(:project, :public, group: group, path: '1') }
  let!(:private_project) { create(:project, :private, group: group, path: '2') }
  let!(:shared_project_1) { create(:project, :public, path: '3') }
  let!(:shared_project_2) { create(:project, :private, path: '4') }
  let!(:shared_project_3) { create(:project, :internal, path: '5') }

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

      it { is_expected.to match_array([private_project, public_project]) }
    end

    context "all" do
      it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
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
        end

        it { is_expected.to match_array([private_project, public_project]) }
      end

      context "with external user" do
        before do
          current_user.update_attributes(external: true)
        end

        it { is_expected.to eq([public_project]) }
      end
    end

    context "all" do
      it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, public_project]) }
    end
  end

  describe 'with an admin current user' do
    let(:current_user) { create(:admin) }

    context "only shared" do
      let(:options) { { only_shared: true } }
      it            { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }
      it            { is_expected.to eq([private_project, public_project]) }
    end

    context "all" do
      it { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
    end
  end

  describe 'with an auditor current user' do
    let(:current_user) { create(:user, :auditor) }

    context "only shared" do
      let(:options) { { only_shared: true } }
      it            { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }
      it      { is_expected.to eq([private_project, public_project]) }
    end

    context "all" do
      subject { described_class.new(group: group, current_user: current_user).execute }
      it      { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
    end
  end

  describe "no user" do
    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      it { is_expected.to eq([public_project]) }
    end
  end
end
