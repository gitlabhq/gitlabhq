require 'spec_helper'

describe Profiles::TwoFactorAuthsController do
  before do
    # `user` should be defined within the action-specific describe blocks
    sign_in(user)

    allow(subject).to receive(:current_user).and_return(user)
  end

  describe 'GET new' do
    let(:user) { create(:user) }

    it 'generates otp_secret' do
      expect { get :new }.to change { user.otp_secret }
    end

    it 'assigns qr_code' do
      code = double('qr code')
      expect(subject).to receive(:build_qr_code).and_return(code)

      get :new
      expect(assigns[:qr_code]).to eq code
    end
  end

  describe 'POST create' do
    let(:user) { create(:user) }
    let(:pin)  { 'pin-code' }

    def go
      post :create, pin_code: pin
    end

    context 'with valid pin' do
      before do
        expect(user).to receive(:valid_otp?).with(pin).and_return(true)
      end

      it 'sets otp_required_for_login' do
        go

        user.reload
        expect(user.otp_required_for_login).to eq true
      end

      it 'presents plaintext codes for the user to save' do
        expect(user).to receive(:generate_otp_backup_codes!).and_return(%w(a b c))

        go

        expect(assigns[:codes]).to match_array %w(a b c)
      end

      it 'renders create' do
        go
        expect(response).to render_template(:create)
      end
    end

    context 'with invalid pin' do
      before do
        expect(user).to receive(:valid_otp?).with(pin).and_return(false)
      end

      it 'assigns error' do
        go
        expect(assigns[:error]).to eq 'Invalid pin code'
      end

      it 'assigns qr_code' do
        code = double('qr code')
        expect(subject).to receive(:build_qr_code).and_return(code)

        go
        expect(assigns[:qr_code]).to eq code
      end

      it 'renders new' do
        go
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'POST codes' do
    let(:user) { create(:user, :two_factor) }

    it 'presents plaintext codes for the user to save' do
      expect(user).to receive(:generate_otp_backup_codes!).and_return(%w(a b c))

      post :codes
      expect(assigns[:codes]).to match_array %w(a b c)
    end

    it 'persists the generated codes' do
      post :codes

      user.reload
      expect(user.otp_backup_codes).not_to be_empty
    end
  end

  describe 'DELETE destroy' do
    let(:user)   { create(:user, :two_factor) }
    let!(:codes) { user.generate_otp_backup_codes! }

    it 'clears all 2FA-related fields' do
      expect(user.otp_required_for_login).to eq true
      expect(user.otp_backup_codes).not_to be_nil
      expect(user.encrypted_otp_secret).not_to be_nil

      delete :destroy

      expect(user.otp_required_for_login).to eq false
      expect(user.otp_backup_codes).to be_nil
      expect(user.encrypted_otp_secret).to be_nil
    end

    it 'redirects to profile_account_path' do
      delete :destroy

      expect(response).to redirect_to(profile_account_path)
    end
  end
end
