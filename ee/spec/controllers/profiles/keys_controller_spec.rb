require 'spec_helper'

describe Profiles::KeysController do
  let(:user) { create(:user) }

  describe '#create' do
    it 'logs the audit event' do
      stub_licensed_features(extended_audit_events: true)

      sign_in(user)

      key = build(:key)

      expect { post :create, key: key.attributes }.to change { SecurityEvent.count }.by(1)
    end
  end
end
