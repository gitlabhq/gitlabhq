require 'spec_helper'

describe SessionsController do
  describe '#create' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    context 'when using standard authentications' do
      context 'invalid password' do
        it 'does not authenticate user' do
          post(:create, user: { login: 'invalid', password: 'invalid' })

          expect(response)
            .to set_flash.now[:alert].to /Invalid Login or password/
        end
      end

      context 'when using valid password' do
        let(:user) { create(:user) }

        it 'authenticates user correctly' do
          post(:create, user: { login: user.username, password: user.password })

          expect(response).to set_flash.to /Signed in successfully/
          expect(subject.current_user). to eq user
        end

        it "creates an audit log record" do
          expect { post(:create, user: { login: user.username, password: user.password }) }.to change { SecurityEvent.count }.by(1)
          expect(SecurityEvent.last.details[:with]).to eq("standard")
        end

        it 'updates the user activity' do
          expect do
            post(:create, user: { login: user.username, password: user.password })
          end.to change { user.reload.last_activity_at }.from(nil)
        end
      end
    end

    context 'when using two-factor authentication via OTP' do
      let(:user) { create(:user, :two_factor) }

      def authenticate_2fa(user_params)
        post(:create, { user: user_params }, { otp_user_id: user.id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).
            to receive(:remember_me).with(user).and_call_original

          authenticate_2fa(remember_me: '1', otp_attempt: user.current_otp)

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa(remember_me: '0', otp_attempt: user.current_otp)

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      ##
      # See #14900 issue
      #
      context 'when authenticating with login and OTP of another user' do
        context 'when another user has 2FA enabled' do
          let(:another_user) { create(:user, :two_factor) }

          context 'when OTP is valid for another user' do
            it 'does not authenticate' do
              authenticate_2fa(login: another_user.username,
                               otp_attempt: another_user.current_otp)

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when OTP is invalid for another user' do
            it 'does not authenticate' do
              authenticate_2fa(login: another_user.username,
                               otp_attempt: 'invalid')

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when authenticating with OTP' do
            context 'when OTP is valid' do
              it 'authenticates correctly' do
                authenticate_2fa(otp_attempt: user.current_otp)

                expect(subject.current_user).to eq user
              end
            end

            context 'when OTP is invalid' do
              before { authenticate_2fa(otp_attempt: 'invalid') }

              it 'does not authenticate' do
                expect(subject.current_user).not_to eq user
              end

              it 'warns about invalid OTP code' do
                expect(response).to set_flash.now[:alert]
                  .to /Invalid two-factor code/
              end
            end
          end

          context 'when the user is on their last attempt' do
            before do
              user.update(failed_attempts: User.maximum_attempts.pred)
            end

            context 'when OTP is valid' do
              it 'authenticates correctly' do
                authenticate_2fa(otp_attempt: user.current_otp)

                expect(subject.current_user).to eq user
              end
            end

            context 'when OTP is invalid' do
              before { authenticate_2fa(otp_attempt: 'invalid') }

              it 'does not authenticate' do
                expect(subject.current_user).not_to eq user
              end

              it 'warns about invalid login' do
                expect(response).to set_flash.now[:alert]
                  .to /Invalid Login or password/
              end

              it 'locks the user' do
                expect(user.reload).to be_access_locked
              end

              it 'keeps the user locked on future login attempts' do
                post(:create, user: { login: user.username, password: user.password })

                expect(response)
                  .to set_flash.now[:alert].to /Invalid Login or password/
              end
            end
          end

          context 'when another user does not have 2FA enabled' do
            let(:another_user) { create(:user) }

            it 'does not leak that 2FA is disabled for another user' do
              authenticate_2fa(login: another_user.username,
                               otp_attempt: 'invalid')

              expect(response).to set_flash.now[:alert]
                .to /Invalid two-factor code/
            end
          end
        end
      end

      it "creates an audit log record" do
        expect { authenticate_2fa(login: user.username, otp_attempt: user.current_otp) }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:with]).to eq("two-factor")
      end
    end

    context 'when using two-factor authentication via U2F device' do
      let(:user) { create(:user, :two_factor) }

      def authenticate_2fa_u2f(user_params)
        post(:create, { user: user_params }, { otp_user_id: user.id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(U2fRegistration).to receive(:authenticate).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).
            to receive(:remember_me).with(user).and_call_original

          authenticate_2fa_u2f(remember_me: '1', login: user.username, device_response: "{}")

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow(U2fRegistration).to receive(:authenticate).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa_u2f(remember_me: '0', login: user.username, device_response: "{}")

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      it "creates an audit log record" do
        allow(U2fRegistration).to receive(:authenticate).and_return(true)
        expect { authenticate_2fa_u2f(login: user.username, device_response: "{}") }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:with]).to eq("two-factor-via-u2f-device")
      end
    end
  end
end
