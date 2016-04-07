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
            .to set_flash.now[:alert].to /Invalid login or password/
        end
      end

      context 'when using valid password' do
        let(:user) { create(:user) }

        it 'authenticates user correctly' do
          post(:create, user: { login: user.username, password: user.password })

          expect(response).to set_flash.to /Signed in successfully/
          expect(subject.current_user). to eq user
        end
      end
    end

    context 'when using two-factor authentication' do
      let(:user) { create(:user, :two_factor) }

      def authenticate_2fa(user_params)
        post(:create, { user: user_params }, { otp_user_id: user.id })
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

              expect(subject.current_user).to_not eq another_user
            end
          end

          context 'when OTP is invalid for another user' do
            it 'does not authenticate' do
              authenticate_2fa(login: another_user.username,
                               otp_attempt: 'invalid')

              expect(subject.current_user).to_not eq another_user
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
                expect(subject.current_user).to_not eq user
              end

              it 'warns about invalid OTP code' do
                expect(response).to set_flash.now[:alert]
                  .to /Invalid two-factor code/
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
    end
  end
end
