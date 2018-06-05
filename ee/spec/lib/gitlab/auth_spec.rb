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

  describe '#build_access_token_check' do
    subject { gl_auth.find_for_git_client('gitlab-ci-token', build.token, project: build.project, ip: '1.2.3.4') }

    context 'for running build' do
      let!(:build) { create(:ci_build, :running, user: user) }

      it 'executes query using primary database' do
        expect(Ci::Build).to receive(:find_by_token).with(build.token).and_wrap_original do |m, *args|
          expect(::Gitlab::Database::LoadBalancing::Session.current.use_primary?).to eq(true)
          m.call(*args)
        end

        expect(subject).to be_a(Gitlab::Auth::Result)
        expect(subject.actor).to eq(user)
        expect(subject.project).to eq(build.project)
        expect(subject.type).to eq(:build)
      end
    end
  end
end
