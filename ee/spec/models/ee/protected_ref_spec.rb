require 'spec_helper'

describe EE::ProtectedRef do
  context 'for protected branches' do
    it 'deletes all related access levels' do
      protected_branch = create(:protected_branch)
      2.times { protected_branch.merge_access_levels.create!(group: create(:group)) }
      2.times { protected_branch.push_access_levels.create!(user: create(:user)) }

      protected_branch.destroy

      expect(ProtectedBranch::MergeAccessLevel.count).to be(0)
      expect(ProtectedBranch::PushAccessLevel.count).to be(0)
    end
  end
end
