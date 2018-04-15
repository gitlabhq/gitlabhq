require 'spec_helper'

describe ProtectedBranchPolicy do
  let(:user) { create(:user) }
  let(:name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: name) }
  let(:project) { protected_branch.project }
  let(:allowed_group) { create(:group) }

  subject { described_class.new(user, protected_branch) }

  before do
    project.add_master(user)
  end

  context 'when unprotection is limited by access levels' do
    before do
      protected_branch.unprotect_access_levels.create!(group: allowed_group)
    end

    context 'when unprotection restriction feature is unlicensed' do
      it "users can remove protections" do
        is_expected.to be_allowed(:update_protected_branch)
        is_expected.to be_allowed(:destroy_protected_branch)
      end
    end

    context 'when unprotection restriction feature is licensed' do
      before do
        stub_licensed_features(unprotection_restrictions: true)
      end

      it "users can't remove protections without specific access" do
        is_expected.not_to be_allowed(:update_protected_branch)
        is_expected.not_to be_allowed(:destroy_protected_branch)
      end

      context "and access levels grant the user control" do
        before do
          allowed_group.add_user(user, :guest)
        end

        it 'users can manage protections' do
          is_expected.to be_allowed(:update_protected_branch)
          is_expected.to be_allowed(:update_protected_branch)
          is_expected.to be_allowed(:destroy_protected_branch)
        end
      end
    end
  end

  context 'creating restrictions' do
    let(:unprotect_access_levels) { [{ group_id: allowed_group.id }] }
    let(:protected_branch) { build(:protected_branch, name: name, unprotect_access_levels_attributes: unprotect_access_levels) }

    before do
      stub_licensed_features(unprotection_restrictions: true)
    end

    it "is prevented if the user wouldn't be able to remove the restriction" do
      is_expected.not_to be_allowed(:create_protected_branch)
    end

    context 'when the user can remove the restriction' do
      before do
        allowed_group.add_user(user, :guest)
      end

      it "is allowed" do
        is_expected.to be_allowed(:create_protected_branch)
      end
    end
  end
end
