require 'spec_helper'

describe Keys::DestroyService do
  let(:user) { create(:user) }
  let(:key) { create(:ldap_key) }

  subject { described_class.new(user) }

  it 'does not destroy LDAP key' do
    key = create(:ldap_key)

    expect { subject.execute(key) }.not_to change(Key, :count)
    expect(key).not_to be_destroyed
  end
end
