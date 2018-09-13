require 'spec_helper'

describe MergeRequestPresenter do
  let(:resource) { create :merge_request, source_project: project }
  let!(:project) { create(:project, :repository) }
  let!(:user) { project.creator }

  describe '#approvals_path' do
    subject { described_class.new(resource, current_user: user).approvals_path }

    it 'returns path' do
      is_expected.to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}/approvals")
    end
  end

  describe '#approvers_left' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: resource, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: resource, group: private_group) }
    let!(:approver) { create(:approver, target: resource) }

    before do
      resource.approvals.create!(user: approver.user)
    end

    subject { described_class.new(resource, current_user: user).approvers_left }

    it { is_expected.to match_array(public_approver_group.users) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it do
        approvers = public_approver_group.users + private_approver_group.users - [user]

        is_expected.to match_array(approvers)
      end
    end
  end

  describe '#overall_approver_groups' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: resource, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: resource, group: private_group) }

    subject { described_class.new(resource, current_user: user).overall_approver_groups }

    it { is_expected.to match_array([public_approver_group]) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it { is_expected.to match_array([public_approver_group, private_approver_group]) }
    end
  end

  describe '#all_approvers_including_groups' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: resource, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: resource, group: private_group) }
    let!(:approver) { create(:approver, target: resource) }

    subject { described_class.new(resource, current_user: user).all_approvers_including_groups }

    it { is_expected.to match_array(public_approver_group.users + [approver.user]) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it do
        approvers = [public_approver_group.users, private_approver_group.users, approver.user].flatten - [user]

        is_expected.to match_array(approvers)
      end
    end
  end
end
