# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvitesController, :snowplow do
  let_it_be(:user) { create(:user) }
  let(:member) { create(:project_member, :invited, invite_email: user.email) }
  let(:raw_invite_token) { member.raw_invite_token }
  let(:project_members) { member.source.users }
  let(:md5_member_global_id) { Digest::MD5.hexdigest(member.to_global_id.to_s) }
  let(:params) { { id: raw_invite_token } }

  shared_examples 'invalid token' do
    context 'when invite token is not valid' do
      let(:params) { { id: '_bogus_token_' } }

      it 'renders the 404 page' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples "tracks the 'accepted' event for the invitation reminders experiment" do
    before do
      stub_experiment(invitation_reminders: true)
      allow(Gitlab::Experimentation).to receive(:enabled_for_attribute?).with(:invitation_reminders, member.invite_email).and_return(experimental_group)
    end

    context 'when in the control group' do
      let(:experimental_group) { false }

      it "tracks the 'accepted' event" do
        request

        expect_snowplow_event(
          category: 'Growth::Acquisition::Experiment::InvitationReminders',
          label: md5_member_global_id,
          property: 'control_group',
          action: 'accepted'
        )
      end
    end

    context 'when in the experimental group' do
      let(:experimental_group) { true }

      it "tracks the 'accepted' event" do
        request

        expect_snowplow_event(
          category: 'Growth::Acquisition::Experiment::InvitationReminders',
          label: md5_member_global_id,
          property: 'experimental_group',
          action: 'accepted'
        )
      end
    end
  end

  describe 'GET #show' do
    subject(:request) { get :show, params: params }

    context 'when logged in' do
      before do
        sign_in(user)
      end

      it 'accepts user if invite email matches signed in user' do
        expect do
          request
        end.to change { project_members.include?(user) }.from(false).to(true)

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:notice]).to include 'You have been granted'
      end

      it 'forces re-confirmation if email does not match signed in user' do
        member.update!(invite_email: 'bogus@email.com')

        expect do
          request
        end.not_to change { project_members.include?(user) }

        expect(response).to have_gitlab_http_status(:ok)
        expect(flash[:notice]).to be_nil
      end

      it_behaves_like "tracks the 'accepted' event for the invitation reminders experiment"
      it_behaves_like 'invalid token'
    end

    context 'when not logged in' do
      context 'when inviter is a member' do
        it 'is redirected to a new session with invite email param' do
          request

          expect(response).to redirect_to(new_user_session_path(invite_email: member.invite_email))
        end
      end

      context 'when inviter is not a member' do
        let(:params) { { id: '_bogus_token_' } }

        it 'is redirected to a new session' do
          request

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'POST #accept' do
    before do
      sign_in(user)
    end

    subject(:request) { post :accept, params: params }

    it_behaves_like "tracks the 'accepted' event for the invitation reminders experiment"
    it_behaves_like 'invalid token'
  end

  describe 'POST #decline for link in UI' do
    before do
      sign_in(user)
    end

    subject(:request) { post :decline, params: params }

    it_behaves_like 'invalid token'
  end

  describe 'GET #decline for link in email' do
    before do
      sign_in(user)
    end

    subject(:request) { get :decline, params: params }

    it_behaves_like 'invalid token'
  end
end
