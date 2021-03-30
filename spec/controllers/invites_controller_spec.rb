# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvitesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:member, reload: true) { create(:project_member, :invited, invite_email: user.email) }
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

      it_behaves_like 'invalid token'

      context 'when invite comes from the initial email invite' do
        let(:params) { { id: raw_invite_token, invite_type: Members::InviteEmailExperiment::INVITE_TYPE } }

        it 'tracks via experiment', :aggregate_failures do
          experiment = double(track: true)
          allow(controller).to receive(:experiment).and_return(experiment)

          request

          expect(experiment).to have_received(:track).with(:opened)
          expect(experiment).to have_received(:track).with(:accepted)
        end
      end

      context 'when invite does not come from initial email invite' do
        it 'does not track via experiment' do
          expect(controller).not_to receive(:experiment)

          request
        end
      end
    end

    context 'when not logged in' do
      context 'when inviter is a member' do
        context 'when instance allows sign up' do
          it 'indicates an account can be created in notice' do
            request

            expect(flash[:notice]).to include('or create an account')
          end

          context 'when user exists with the invited email' do
            it 'is redirected to a new session with invite email param' do
              request

              expect(response).to redirect_to(new_user_session_path(invite_email: member.invite_email))
            end
          end

          context 'when user exists with the invited email as secondary email' do
            before do
              secondary_email = create(:email, user: user, email: 'foo@example.com')
              member.update!(invite_email: secondary_email.email)
            end

            it 'is redirected to a new session with invite email param' do
              request

              expect(response).to redirect_to(new_user_session_path(invite_email: member.invite_email))
            end
          end

          context 'when user does not exist with the invited email' do
            before do
              member.update!(invite_email: 'bogus_email@example.com')
            end

            it 'indicates an account can be created in notice' do
              request

              expect(flash[:notice]).to include('create an account or sign in')
            end

            it 'is redirected to a new registration with invite email param' do
              request

              expect(response).to redirect_to(new_user_registration_path(invite_email: member.invite_email))
            end
          end
        end

        context 'when instance does not allow sign up' do
          before do
            stub_application_setting(allow_signup?: false)
          end

          it 'does not indicate an account can be created in notice' do
            request

            expect(flash[:notice]).not_to include('or create an account')
          end

          context 'when user exists with the invited email' do
            it 'is redirected to a new session with invite email param' do
              request

              expect(response).to redirect_to(new_user_session_path(invite_email: member.invite_email))
            end
          end

          context 'when user does not exist with the invited email' do
            before do
              member.update!(invite_email: 'bogus_email@example.com')
            end

            it 'is redirected to a new session with invite email param' do
              request

              expect(response).to redirect_to(new_user_session_path(invite_email: member.invite_email))
            end
          end
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

    it_behaves_like 'invalid token'

    context 'when invite comes from the initial email invite' do
      it 'tracks via experiment' do
        experiment = double(track: true)
        allow(controller).to receive(:experiment).and_return(experiment)

        post :accept, params: params, session: { invite_type: Members::InviteEmailExperiment::INVITE_TYPE }

        expect(experiment).to have_received(:track).with(:accepted)
      end
    end

    context 'when invite does not come from initial email invite' do
      it 'does not track via experiment' do
        expect(controller).not_to receive(:experiment)

        request
      end
    end
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
