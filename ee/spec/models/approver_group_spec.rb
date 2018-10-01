require 'spec_helper'

describe ApproverGroup do
  subject { create(:approver_group) }

  it { is_expected.to be_valid }

  describe '.filtered_approver_groups' do
    let!(:project) { create(:project) }
    let!(:user) { project.creator }
    let!(:private_group) { create(:group, :private) }
    let!(:public_approver_group) { create(:approver_group, target: project) }
    let!(:private_approver_group) { create(:approver_group, target: project, group: private_group) }

    subject { described_class.filtered_approver_groups(project.approver_groups, user) }

    it { is_expected.to match_array([public_approver_group]) }

    context 'when user has access to private group' do
      before do
        private_group.add_user(user, Gitlab::Access::DEVELOPER)
      end

      it { is_expected.to match_array([public_approver_group, private_approver_group]) }
    end
  end
end
