# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::SshKeysController, feature_category: :user_profile do
  let(:user) { create(:user) }

  describe 'POST #create' do
    before do
      sign_in(user)
    end

    it 'creates a new key' do
      expires_at = 3.days.from_now

      expect do
        post :create, params: { key: build(:key, usage_type: :signing, expires_at: expires_at).attributes }
      end.to change { Key.count }.by(1)

      key = Key.last
      expect(key.expires_at).to be_like_time(expires_at)
      expect(key.fingerprint_md5).to be_present
      expect(key.fingerprint_sha256).to be_present
      expect(key.usage_type).to eq('signing')
    end

    context 'with FIPS mode', :fips_mode do
      it 'creates a new key without MD5 fingerprint' do
        expires_at = 3.days.from_now

        expect do
          post :create, params: { key: build(:rsa_key_4096, expires_at: expires_at).attributes }
        end.to change { Key.count }.by(1)

        key = Key.last
        expect(key.expires_at).to be_like_time(expires_at)
        expect(key.fingerprint_md5).to be_nil
        expect(key.fingerprint_sha256).to be_present
      end
    end
  end
end
