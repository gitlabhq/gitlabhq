require 'spec_helper'

describe GroupProjectsFinder do
  let(:group) { create(:group) }
  let(:current_user) { create(:user) }

  let(:finder) { described_class.new(source_user) }

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

  describe 'with a group member current user' do
    before  { group.add_user(current_user, Gitlab::Access::MASTER) }

    context "only shared" do
      subject { described_class.new(group, only_shared: true).execute(current_user) }
      it      { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context "only owned" do
      subject { described_class.new(group, only_owned: true).execute(current_user) }
      it      { is_expected.to eq([private_project, public_project]) }
    end

    context "all" do
      subject { described_class.new(group).execute(current_user) }
      it      { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
    end
  end

  describe 'without group member current_user' do
    before { shared_project_2.team << [current_user, Gitlab::Access::MASTER] }

    context "only shared" do
      context "without external user" do
        subject { described_class.new(group, only_shared: true).execute(current_user) }
        it      { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1]) }
      end

      context "with external user" do
        before  { current_user.update_attributes(external: true) }
        subject { described_class.new(group, only_shared: true).execute(current_user) }
        it      { is_expected.to eq([shared_project_2, shared_project_1]) }
      end
    end

    context "only owned" do
      context "without external user" do
        before  { private_project.team << [current_user, Gitlab::Access::MASTER] }
        subject { described_class.new(group, only_owned: true).execute(current_user) }
        it      { is_expected.to eq([private_project, public_project]) }
      end

      context "with external user" do
        before  { current_user.update_attributes(external: true) }
        subject { described_class.new(group, only_owned: true).execute(current_user) }
        it      { is_expected.to eq([public_project]) }
      end

      context "all" do
        subject { described_class.new(group).execute(current_user) }
        it      { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1, public_project]) }
      end
    end
  end

  describe "no user" do
    context "only shared" do
      subject { described_class.new(group, only_shared: true).execute(current_user) }
      it      { is_expected.to eq([shared_project_3, shared_project_1]) }
    end

    context "only owned" do
      subject { described_class.new(group, only_owned: true).execute(current_user) }
      it      { is_expected.to eq([public_project]) }
    end
  end
end
