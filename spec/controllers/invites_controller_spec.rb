# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvitesController do
  let(:token) { '123456' }
  let_it_be(:user) { create(:user) }
  let(:member) { create(:project_member, :invited, invite_token: token, invite_email: user.email) }
  let(:project_members) { member.source.users }
  let(:md5_member_global_id) { Digest::MD5.hexdigest(member.to_global_id.to_s) }

  before do
    stub_application_setting(snowplow_enabled: true, snowplow_collector_hostname: 'localhost')
    controller.instance_variable_set(:@member, member)
    sign_in(user)
  end

  describe 'GET #show' do
    let(:params) { { id: token } }

    subject(:request) { get :show, params: params }

    it 'accepts user if invite email matches signed in user' do
      expect do
        request
      end.to change { project_members.include?(user) }.from(false).to(true)

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include 'You have been granted'
    end

    it 'forces re-confirmation if email does not match signed in user' do
      member.invite_email = 'bogus@email.com'

      expect do
        request
      end.not_to change { project_members.include?(user) }

      expect(response).to have_gitlab_http_status(:ok)
      expect(flash[:notice]).to be_nil
    end

    context 'when new_user_invite is not set' do
      it 'does not track the user as experiment group' do
        expect(Gitlab::Tracking).not_to receive(:event)

        request
      end
    end

    context 'when new_user_invite is experiment' do
      let(:params) { { id: token, new_user_invite: 'experiment' } }

      it 'tracks the user as experiment group' do
        expect(Gitlab::Tracking).to receive(:event).and_call_original.with(
          'Growth::Acquisition::Experiment::InviteEmail',
          'opened',
          property: 'experiment_group',
          label: md5_member_global_id
        )
        expect(Gitlab::Tracking).to receive(:event).and_call_original.with(
          'Growth::Acquisition::Experiment::InviteEmail',
          'accepted',
          property: 'experiment_group',
          label: md5_member_global_id
        )

        request
      end
    end

    context 'when new_user_invite is control' do
      let(:params) { { id: token, new_user_invite: 'control' } }

      it 'tracks the user as control group' do
        expect(Gitlab::Tracking).to receive(:event).and_call_original.with(
          'Growth::Acquisition::Experiment::InviteEmail',
          'opened',
          property: 'control_group',
          label: md5_member_global_id
        )
        expect(Gitlab::Tracking).to receive(:event).and_call_original.with(
          'Growth::Acquisition::Experiment::InviteEmail',
          'accepted',
          property: 'control_group',
          label: md5_member_global_id
        )

        request
      end
    end
  end

  describe 'POST #accept' do
    let(:params) { { id: token } }

    subject(:request) { post :accept, params: params }

    context 'when new_user_invite is not set' do
      it 'does not track an event' do
        expect(Gitlab::Tracking).not_to receive(:event)

        request
      end
    end

    context 'when new_user_invite is experiment' do
      let(:params) { { id: token, new_user_invite: 'experiment' } }

      it 'tracks the user as experiment group' do
        expect(Gitlab::Tracking).to receive(:event).and_call_original.with(
          'Growth::Acquisition::Experiment::InviteEmail',
          'accepted',
          property: 'experiment_group',
          label: md5_member_global_id
        )

        request
      end
    end

    context 'when new_user_invite is control' do
      let(:params) { { id: token, new_user_invite: 'control' } }

      it 'tracks the user as control group' do
        expect(Gitlab::Tracking).to receive(:event).and_call_original.with(
          'Growth::Acquisition::Experiment::InviteEmail',
          'accepted',
          property: 'control_group',
          label: md5_member_global_id
        )

        request
      end
    end
  end
end
