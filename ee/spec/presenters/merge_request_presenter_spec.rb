require 'spec_helper'

describe MergeRequestPresenter do
  let(:resource) { create :merge_request, source_project: project }
  let!(:project) { create(:project, :repository) }
  let!(:user) { project.creator }

  describe '#all_approvers_including_groups' do
    let!(:private_group) { create(:group_with_members, :private) }
    let!(:public_group) { create(:group_with_members) }
    let!(:public_approver_group) { create(:approver_group, target: resource, group: public_group) }
    let!(:private_approver_group) { create(:approver_group, target: resource, group: private_group) }
    let!(:approver) { create(:approver, target: resource) }

    subject { described_class.new(resource, current_user: user).all_approvers_including_groups }

    it { is_expected.to match_array([public_approver_group.users, approver.user].flatten) }

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

  describe '#overall_approver_groups' do
    subject { described_class.new(resource, current_user: user).overall_approver_groups }

    context 'when approvers is overwritten' do
      let!(:public_approver_group) { create(:approver_group, target: project) }

      it { is_expected.to match_array(project.approver_groups) }
    end

    context 'when approvers is not overwritten' do
      let!(:public_approver_group) { create(:approver_group, target: resource) }

      it { is_expected.to match_array([public_approver_group]) }
    end
  end

  describe '#approvers_overwritten?' do
    subject { described_class.new(resource, current_user: user).approvers_overwritten? }

    it { is_expected.to be_falsey }

    context 'when merge request has user and group approvers' do
      let!(:public_approver_group) { create(:approver_group, target: resource) }
      let!(:approver) { create(:approver, user: user, target: resource) }

      it { is_expected.to be_truthy }
    end

    context 'when merge request only has user approvers' do
      let!(:approver) { create(:approver, user: user, target: resource) }

      it { is_expected.to be_truthy }
    end

    context 'when merge request only has group approvers' do
      let!(:public_approver_group) { create(:approver_group, target: resource) }

      it { is_expected.to be_truthy }
    end
  end
end
