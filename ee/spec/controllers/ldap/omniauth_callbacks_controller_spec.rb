require 'spec_helper'

describe Ldap::OmniauthCallbacksController do
  include_context 'Ldap::OmniauthCallbacksController'

  it "displays LDAP sync flash on first sign in" do
    post provider

    expect(flash[:notice]).to match(/LDAP sync in progress*/)
  end

  it "skips LDAP sync flash on subsequent sign ins" do
    user.update!(sign_in_count: 1)

    post provider

    expect(flash[:notice]).to eq nil
  end

  context 'access denied' do
    let(:valid_login?) { false }

    it 'logs a failure event' do
      stub_licensed_features(extended_audit_events: true)

      expect { post provider }.to change(SecurityEvent, :count).by(1)
    end
  end
end
