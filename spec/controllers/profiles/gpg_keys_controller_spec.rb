# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::GpgKeysController do
  let(:user) { create(:user, email: GpgHelpers::User1.emails[0]) }

  describe 'POST #create' do
    before do
      sign_in(user)
    end

    it 'creates a new key' do
      expect do
        post :create, params: { gpg_key: build(:gpg_key).attributes }
      end.to change { GpgKey.count }.by(1)
    end
  end
end
