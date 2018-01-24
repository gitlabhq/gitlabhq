require 'spec_helper'

describe Gitlab::Geo::JwtRequestDecoder do
  let!(:primary_node) { FactoryBot.create(:geo_node, :primary) }
  let(:data) { { input: 123 } }
  let(:request) { Gitlab::Geo::TransferRequest.new(data) }

  subject { described_class.new(request.headers['Authorization']) }

  describe '#decode' do
    it 'decodes correct data' do
      expect(subject.decode).to eq(data)
    end

    it 'fails to decode when node is disabled' do
      primary_node.enabled = false
      primary_node.save

      expect(subject.decode).to be_nil
    end

    it 'fails to decode with wrong key' do
      data = request.headers['Authorization']

      primary_node.secret_access_key = ''
      primary_node.save
      expect(described_class.new(data).decode).to be_nil
    end

    it 'successfully decodes when clocks are off by IAT leeway' do
      subject

      Timecop.travel(30.seconds.ago) { expect(subject.decode).to eq(data) }
    end

    it 'raises InvalidSignatureTimeError after expiring' do
      subject

      Timecop.travel(2.minutes) { expect { subject.decode }.to raise_error(Gitlab::Geo::InvalidSignatureTimeError) }
    end

    it 'raises InvalidSignatureTimeError to decode when clocks are not in sync' do
      subject

      Timecop.travel(2.minutes.ago) { expect { subject.decode }.to raise_error(Gitlab::Geo::InvalidSignatureTimeError) }
    end

    it 'raises invalid decryption key error' do
      allow_any_instance_of(described_class).to receive(:decode_auth_header).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)

      expect { subject.decode }.to raise_error(Gitlab::Geo::InvalidDecryptionKeyError)
    end
  end
end
