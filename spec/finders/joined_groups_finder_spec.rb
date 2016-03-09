require 'spec_helper'

describe JoinedGroupsFinder do
  describe '#execute' do
    let!(:profile_owner)    { create(:user) }
    let!(:profile_visitor)  { create(:user) }

    let!(:private_group)    { create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
    let!(:private_group_2)  { create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
    let!(:internal_group)   { create(:group, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
    let!(:internal_group_2) { create(:group, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
    let!(:public_group)     { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
    let!(:public_group_2)   { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
    let!(:finder) { described_class.new(profile_owner) }

    describe 'execute' do
      context 'without a user only shows public groups from profile owner' do
        before { public_group.add_user(profile_owner, Gitlab::Access::MASTER)}
        subject { finder.execute }

        it { is_expected.to eq([public_group]) }
      end

      context 'only shows groups where both users are authorized to see' do
        subject { finder.execute(profile_visitor) }

        before do
          private_group.add_user(profile_owner, Gitlab::Access::MASTER)
          private_group.add_user(profile_visitor, Gitlab::Access::DEVELOPER)
          internal_group.add_user(profile_owner, Gitlab::Access::MASTER)
          public_group.add_user(profile_owner, Gitlab::Access::MASTER)
        end

        it { is_expected.to eq([public_group, internal_group, private_group]) }
      end

      context 'shows group if profile visitor is in one of its projects' do
        before do
          public_group.add_user(profile_owner, Gitlab::Access::MASTER)
          private_group.add_user(profile_owner, Gitlab::Access::MASTER)
          project = create(:project, :private, group: private_group, name: 'B', path: 'B')
          project.team.add_user(profile_visitor, Gitlab::Access::DEVELOPER)
        end

        subject { finder.execute(profile_visitor) }

        it { is_expected.to eq([public_group, private_group]) }
      end
    end
  end
end
