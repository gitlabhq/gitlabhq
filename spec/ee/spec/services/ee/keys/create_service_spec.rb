require 'spec_helper'

describe Keys::CreateService do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:key) }

  subject { described_class.new(user, params) }

  it 'creates' do
    stub_licensed_features(extended_audit_events: true)

    expect { subject.execute }.to change { SecurityEvent.count }.by(1)
  end
end
