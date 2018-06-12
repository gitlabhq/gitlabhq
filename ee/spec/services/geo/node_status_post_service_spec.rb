require 'spec_helper'

describe Geo::NodeStatusPostService, :geo do
  include ::EE::GeoHelpers
  include ApiHelpers

  set(:primary)   { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  subject { described_class.new }

  describe '#execute' do
    it 'parses a 401 response' do
      response = double(success?: false,
                        code: 401,
                        message: 'Unauthorized',
                        parsed_response: { 'message' => 'Test' } )
      allow(Gitlab::HTTP).to receive(:post).and_return(response)
      expect(subject).to receive(:log_error).with("Could not connect to Geo primary node - HTTP Status Code: 401 Unauthorized\nTest")

      expect(subject.execute(secondary.find_or_build_status)).to be_falsey
    end

    it 'alerts on bad SSL certficate' do
      message = 'bad certificate'
      allow(Gitlab::HTTP).to receive(:post).and_raise(OpenSSL::SSL::SSLError.new(message))
      expect(subject).to receive(:log_error).with('Failed to post status data to primary', kind_of(OpenSSL::SSL::SSLError))

      expect(subject.execute(secondary)).to be_falsey
    end

    it 'handles connection refused' do
      allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED.new('bad connection'))

      expect(subject).to receive(:log_error).with('Failed to post status data to primary', kind_of(Errno::ECONNREFUSED))

      expect(subject.execute(secondary)).to be_falsey
    end

    it 'returns meaningful error message when primary uses incorrect db key' do
      allow_any_instance_of(GeoNode).to receive(:secret_access_key).and_raise(OpenSSL::Cipher::CipherError)

      expect(subject).to receive(:log_error).with(
        "Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.",
        kind_of(OpenSSL::Cipher::CipherError)
      )

      expect(subject.execute(secondary)).to be_falsey
    end

    it 'gracefully handles case when primary is deleted' do
      primary.destroy!

      expect(subject).to receive(:log_error).with(
        'Failed to look up Geo primary node in the database'
      )

      expect(subject.execute(secondary)).to be_falsey
    end

    it 'sends geo_node_id in the request' do
      stub_current_geo_node(primary)

      expect(Gitlab::HTTP).to receive(:post)
                                .with(
                                  primary.status_url,
                                  hash_including(body: hash_including('geo_node_id' => secondary.id)))
                                .and_return(double(success?: true))

      subject.execute(GeoNodeStatus.new({
        geo_node_id: secondary.id,
        status_message: nil,
        db_replication_lag_seconds: 0,
        repositories_count: 10
      }))
    end
  end
end
