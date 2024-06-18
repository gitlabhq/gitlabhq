# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::PendingInvitationsFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:user, reload: true) { create(:user, email: 'user@email.com') }
    let(:invite_emails) { [user.email] }

    subject(:execute) { described_class.new(invite_emails).execute }

    context 'when the invite_email is the same case as the user email' do
      let_it_be(:invited_member) do
        create(:project_member, :invited, invite_email: user.email)
      end

      it 'finds the invite' do
        expect(execute).to match_array([invited_member])
      end
    end

    context 'when there is a non-lowercased private commit email' do
      let_it_be(:invite_emails) do
        ["#{user.id}-BOBBY_TABLES@#{Gitlab::CurrentSettings.current_application_settings.commit_email_hostname}"]
      end

      let_it_be(:invited_member) do
        create(:project_member, :invited, invite_email: invite_emails.first)
      end

      before do
        user.update!(username: 'BOBBY_TABLES')
      end

      it 'finds the invite' do
        expect(execute).to match_array([invited_member])
      end
    end

    context 'when the invite has already been accepted' do
      let_it_be(:invited_member) do
        create(:project_member, :invited, invite_email: user.email)
      end

      it 'finds only the valid pending invite' do
        create(:project_member, :invited, invite_email: user.email).accept_invite!(user)

        expect(execute).to match_array([invited_member])
      end
    end

    context 'when the invite_email is a different case than the user email' do
      let_it_be(:upper_case_existing_invite) do
        create(:project_member, :invited, invite_email: user.email.upcase)
      end

      it 'finds the invite' do
        expect(execute).to match_array([upper_case_existing_invite])
      end
    end

    context 'with an uppercase version of the email matches another member' do
      let_it_be(:project_member_invite) { create(:project_member, :invited, invite_email: user.email) }
      let_it_be(:upper_case_existing_invite) do
        create(:project_member, :invited, source: project_member_invite.project, invite_email: user.email.upcase)
      end

      it 'contains only the latest updated case insensitive email invite' do
        travel_to 10.minutes.ago do
          project_member_invite.touch # in past, so shouldn't get accepted over the one created
        end

        upper_case_existing_invite.touch # ensure updated_at is being verified. This one should be first now.

        travel_to 10.minutes.from_now do
          project_member_invite.touch # now we'll make the original first so we are verifying updated_at

          expect(execute).to match_array([project_member_invite])
        end
      end
    end
  end
end
