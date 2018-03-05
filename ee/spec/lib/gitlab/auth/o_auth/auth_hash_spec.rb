require 'spec_helper'

describe Gitlab::Auth::OAuth::AuthHash do
  let(:auth_hash) do
    described_class.new(
      OmniAuth::AuthHash.new(
        provider: ascii('kerberos'),
        uid: ascii(uid),
        info: { uid: ascii(uid) }
      )
    )
  end

  describe '#uid' do
    subject { auth_hash.uid }

    context 'contains a kerberos realm' do
      let(:uid) { 'mylogin@BAR.COM' }

      it 'preserves the canonical uid' do
        is_expected.to eq('mylogin@BAR.COM')
      end
    end

    context 'does not contain a kerberos realm' do
      let(:uid) { 'mylogin' }

      before do
        allow(Gitlab::Kerberos::Authentication).to receive(:kerberos_default_realm).and_return('FOO.COM')
      end

      it 'canonicalizes uid with kerberos realm' do
        is_expected.to eq('mylogin@FOO.COM')
      end
    end
  end

  def ascii(text)
    text.force_encoding(Encoding::ASCII_8BIT)
  end
end
