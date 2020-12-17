# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::KeysController do
  let(:user) { create(:user) }

  describe 'POST #create' do
    before do
      sign_in(user)
    end

    it 'creates a new key' do
      expires_at = 3.days.from_now

      expect do
        post :create, params: { key: build(:key, expires_at: expires_at).attributes }
      end.to change { Key.count }.by(1)

      expect(Key.last.expires_at).to be_like_time(expires_at)
    end
  end
end
