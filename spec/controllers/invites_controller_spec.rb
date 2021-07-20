# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvitesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:member, reload: true) { create(:project_member, :invited, invite_email: user.email) }

  let(:raw_invite_token) { member.raw_invite_token }
  let(:project_members) { member.source.users }
  let(:md5_member_global_id) { Digest::MD5.hexdigest(member.to_global_id.to_s) }
  let(:extra_params) { {} }
  let(:params) { { id: raw_invite_token }.merge(extra_params) }

  shared_examples 'invalid token' do
    context 'when invite token is not valid' do
      let(:raw_invite_token) { '_bogus_token_' }

      it 'redirects to root' do
        request

        expect(response).to redirect_to(root_path)
        expect(controller).to set_flash[:alert].to('The invitation can not be found with the provided invite token.')
      end
    end
  end

  describe 'GET #show' do
    subject(:request) { get :show, params: params }

    context 'when it is part of our invite email experiment' do
      let(:extra_params) { { invite_type: 'initial_email' } }

      it 'tracks the experiment' do
        experiment = double(track: true)
        allow(controller).to receive(:experiment).with('members/invite_email', actor: member).and_return(experiment)

        request

        expect(experiment).to have_received(:track).with(:join_clicked)
      end

      context 'when member does not exist' do
        let(:raw_invite_token) { '_bogus_token_' }

        it 'does not track the experiment' do
          expect(controller).not_to receive(:experiment).with('members/invite_email', actor: member)

          request
        end
      end
    end

    context 'when it is not part of our invite email experiment' do
      it 'does not track via experiment' do
        expect(controller).not_to receive(:experiment).with('members/invite_email', actor: member)

        request
      end
    end

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
    end

    context 'when not logged in' do
      context 'when invite token belongs to a valid member' do
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

            it 'is redirected to a new registration with invite email param and flash message', :aggregate_failures do
              request

              expect(response).to redirect_to(new_user_registration_path(invite_email: member.invite_email))
              expect(flash[:notice]).to eq 'To accept this invitation, create an account or sign in.'
            end

            it 'sets session keys for auto email confirmation on sign up' do
              request

              expect(session[:invite_email]).to eq(member.invite_email)
            end

            context 'when it is part of our invite email experiment' do
              let(:extra_params) { { invite_type: 'initial_email' } }

              it 'sets session key for invite acceptance tracking on sign-up' do
                request

                expect(session[:originating_member_id]).to eq(member.id)
              end
            end

            context 'when it is not part of our invite email experiment' do
              it 'does not set the session key for invite acceptance tracking on sign-up' do
                request

                expect(session[:originating_member_id]).to be_nil
              end
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

      context 'when invite token does not belong to a valid member' do
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
