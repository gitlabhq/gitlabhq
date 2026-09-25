# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MembersHelper do
  describe '#remove_member_message' do
    let(:requester) { build_stubbed(:user) }
    let(:project) { build_stubbed(:project, :public) }
    let(:project_member) { build_stubbed(:project_member, source: project) }
    let(:project_member_invite) { build_stubbed(:project_member, :invited, source: project) }
    let(:project_member_request) { build_stubbed(:project_member, :access_request, source: project, user: requester) }
    let(:group) { build_stubbed(:group) }
    let(:group_member) { build_stubbed(:group_member, source: group) }
    let(:group_member_invite) { build_stubbed(:group_member, :invited, source: group) }
    let(:group_member_request) { build_stubbed(:group_member, :access_request, source: group, user: requester) }

    it { expect(remove_member_message(project_member)).to eq "Are you sure you want to remove #{project_member.user.name} from the #{project.full_name} project?" }
    it { expect(remove_member_message(project_member_invite)).to eq "Are you sure you want to revoke the invitation for #{project_member_invite.invite_email} to join the #{project.full_name} project?" }
    it { expect(remove_member_message(project_member_request)).to eq "Are you sure you want to deny #{requester.name}'s request to join the #{project.full_name} project?" }
    it { expect(remove_member_message(project_member_request, user: requester)).to eq "Are you sure you want to withdraw your access request for the #{project.full_name} project?" }
    it { expect(remove_member_message(group_member)).to eq "Are you sure you want to remove #{group_member.user.name} from the #{group.name} group and any subresources?" }
    it { expect(remove_member_message(group_member_invite)).to eq "Are you sure you want to revoke the invitation for #{group_member_invite.invite_email} to join the #{group.name} group?" }
    it { expect(remove_member_message(group_member_request)).to eq "Are you sure you want to deny #{requester.name}'s request to join the #{group.name} group?" }
    it { expect(remove_member_message(group_member_request, user: requester)).to eq "Are you sure you want to withdraw your access request for the #{group.name} group?" }

    context 'an accepted user invitation with no user associated' do
      let(:group_member_invite) do
        build_stubbed(:group_member, source: group, invite_email: "#{SecureRandom.hex}@example.com",
          invite_token: nil, user: nil)
      end

      it 'logs an exception and shows orphaned status' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(anything, hash_including(:member_id, :invite_email, :invite_accepted_at))
        expect(remove_member_message(group_member_invite)).to eq "Are you sure you want to remove this orphaned member from the #{group.name} group and any subresources?"
      end
    end

    context 'a pending member invitation with no user associated' do
      let(:project_member_invite) do
        build_stubbed(:project_member, source: project, invite_email: "#{SecureRandom.hex}@example.com",
          invite_token: 'some-token', user: nil)
      end

      it 'does not error when there is an invitation for the requestor' do
        expect(remove_member_message(project_member_invite)).to eq "Are you sure you want to revoke the invitation for #{project_member_invite.invite_email} to join the #{project.full_name} project?"
      end
    end
  end
end
