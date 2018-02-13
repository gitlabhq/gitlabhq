require "spec_helper"

describe ProjectTeam do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  describe '#add_users' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    context 'when group membership is locked' do
      before do
        group.update_attribute(:membership_lock, true)
      end

      it 'does not add the given users to the team' do
        project.team.add_users([user1, user2], :reporter)

        expect(project.team.reporter?(user1)).to be(false)
        expect(project.team.reporter?(user2)).to be(false)
      end
    end
  end

  describe '#add_user' do
    let(:user) { create(:user) }

    context 'when group membership is locked' do
      before do
        group.update_attribute(:membership_lock, true)
      end

      it 'does not add the given user to the team' do
        project.team.add_user(user, :reporter)

        expect(project.team.reporter?(user)).to be(false)
      end
    end
  end
end
