require 'spec_helper'

feature 'Login' do
  let(:user) { create(:user) }

  context 'with two-factor authentication' do
    before do
      user.otp_required_for_login = true
      user.otp_secret = User.generate_otp_secret
      user.save!
    end

    context 'with valid username/password' do
      before do
        login_with(user)
        expect(page).to have_content('Two-factor Authentication')
      end

      def enter_code(code)
        fill_in 'Two-factor authentication code', with: code
        click_button 'Verify code'
      end

      context 'using one-time code' do
        it 'allows login with valid code' do
          enter_code(user.current_otp)
          expect(current_path).to eq root_path
        end

        it 'blocks login with invalid code' do
          enter_code('foo')
          expect(page).to have_content('Invalid two-factor code')
        end
      end

      context 'using backup code' do
        let(:codes) { user.generate_otp_backup_codes! }

        before do
          expect(codes.size).to eq 5

          # Because `generate_otp_backup_codes!` doesn't actually do this...
          user.save
        end

        context 'with valid code' do
          it 'allows login' do
            enter_code(codes.sample)
            expect(current_path).to eq root_path
          end

          it 'invalidates the used code' do
            # FIXME (rspeicher): Broken library is broken
            expect { enter_code(codes.sample) }.to change { user.otp_backup_codes.size }.by(-1)
          end
        end

        context 'with invalid code' do
          it 'blocks login' do
            # FIXME (rspeicher): Broken library is broken
            code = codes.sample
            expect(user.invalidate_otp_backup_code!(code)).to eq true
            expect(user.otp_backup_codes.size).to eq 4 # Passes
            user.save!
            user.reload
            expect(user.otp_backup_codes.size).to eq 4 # Fails... WAT?!

            enter_code(code)
            expect(page).to have_content('Invalid two-factor code')
          end
        end
      end
    end
  end

  context 'without two-factor authentication' do
    it 'allows basic login' do
      login_with(user)
      expect(current_path).to eq root_path
    end
  end
end
