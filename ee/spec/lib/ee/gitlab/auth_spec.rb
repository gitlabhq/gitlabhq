require 'spec_helper'

describe Gitlab::Auth do
  let(:gl_auth) { described_class }
  let!(:user) do
    create(:user,
           username: username,
           password: password,
           password_confirmation: password)
  end
  let(:username) { 'John' }     # username isn't lowercase, test this
  let(:password) { 'my-secret' }

  context 'with kerberos' do
    before do
      allow(Devise).to receive_messages(omniauth_providers: [:kerberos])
    end

    it 'finds user' do
      expect(::Gitlab::Kerberos::Authentication).to receive_messages(login: user)

      expect( gl_auth.find_with_user_password(username, password) ).to eql user
    end
  end
end
