require 'spec_helper'

describe Geo::NodeStatusFetchService, :geo do
  include ::EE::GeoHelpers

  set(:primary)   { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  subject { described_class.new }

  describe '#call' do
    it 'parses a 401 response' do
      request = double(success?: false,
                       code: 401,
                       message: 'Unauthorized',
                       parsed_response: { 'message' => 'Test' } )
      allow(Gitlab::HTTP).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status.status_message).to eq("Could not connect to Geo node - HTTP Status Code: 401 Unauthorized\nTest")
    end

    it 'always reload GeoNodeStatus if current node' do
      stub_current_geo_node(secondary)
      expect(GeoNodeStatus).to receive(:current_node_status).and_call_original

      status = subject.call(secondary)

      expect(status).to be_a(GeoNodeStatus)
    end

    it 'ignores certain parameters' do
      yesterday = Date.yesterday
      request = double(success?: true,
                       code: 200,
                       message: 'Unauthorized',
                       parsed_response: {
                         'id' => 5000,
                         'last_successful_status_check_at' => yesterday,
                         'created_at' => yesterday,
                         'updated_at' => yesterday
                       })
      allow(described_class).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status.id).not_to be(5000)
      expect(status.last_successful_status_check_at).not_to be(yesterday)
      expect(status.created_at).not_to be(yesterday)
      expect(status.updated_at).not_to be(yesterday)
    end

    it 'parses a 200 legacy response' do
      data = { health: 'OK',
               db_replication_lag_seconds: 0,
               repositories_count: 10,
               repositories_synced_count: 1,
               repositories_failed_count: 2,
               lfs_objects_count: 100,
               lfs_objects_synced_count: 50,
               lfs_objects_failed_count: 12,
               job_artifacts_count: 100,
               job_artifacts_synced_count: 50,
               job_artifacts_failed_count: 12,
               attachments_count: 30,
               attachments_synced_count: 30,
               attachments_failed_count: 25,
               last_event_id: 2,
               last_event_timestamp: Time.now.to_i,
               cursor_last_event_id: 1,
               cursor_last_event_timestamp: Time.now.to_i }
      request = double(success?: true, parsed_response: data.stringify_keys, code: 200)
      allow(Gitlab::HTTP).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status).to have_attributes(data)
      expect(status.success).to be true
    end

    it 'omits full response text in status' do
      request = double(success?: false,
                       code: 401,
                       message: 'Unauthorized',
                       parsed_response: '<html><h1>You are not allowed</h1></html>')
      allow(Gitlab::HTTP).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status.status_message).to eq("Could not connect to Geo node - HTTP Status Code: 401 Unauthorized\n")
      expect(status.success).to be false
    end

    it 'alerts on bad SSL certficate' do
      message = 'bad certificate'
      allow(Gitlab::HTTP).to receive(:get).and_raise(OpenSSL::SSL::SSLError.new(message))

      status = subject.call(secondary)

      expect(status.status_message).to eq(message)
    end

    it 'handles connection refused' do
      allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED.new('bad connection'))

      status = subject.call(secondary)

      expect(status.status_message).to eq('Connection refused - bad connection')
    end

    it 'returns meaningful error message when primary uses incorrect db key' do
      allow_any_instance_of(GeoNode).to receive(:secret_access_key).and_raise(OpenSSL::Cipher::CipherError)

      status = subject.call(secondary)

      expect(status.status_message).to eq('Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.')
    end

    it 'gracefully handles case when primary is deleted' do
      primary.destroy!

      status = subject.call(secondary)

      expect(status.status_message).to eq('This GitLab instance does not appear to be configured properly as a Geo node. Make sure the URLs are using the correct fully-qualified domain names.')
    end

    it 'returns the status from database if it could not fetch it' do
      allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED.new('bad connection'))
      db_status = create(:geo_node_status, :healthy, geo_node: secondary)

      status = subject.call(secondary)

      expect(status.status_message).to eq('Connection refused - bad connection')
      expect(status).not_to be_healthy
      expect(status.attachments_count).to eq(db_status.attachments_count)
      expect(status.attachments_failed_count).to eq(db_status.attachments_failed_count)
      expect(status.attachments_synced_count).to eq(db_status.attachments_synced_count)
      expect(status.lfs_objects_count).to eq(db_status.lfs_objects_count)
      expect(status.lfs_objects_failed_count).to eq(db_status.lfs_objects_failed_count)
      expect(status.lfs_objects_synced_count).to eq(db_status.lfs_objects_synced_count)
      expect(status.job_artifacts_count).to eq(db_status.job_artifacts_count)
      expect(status.job_artifacts_failed_count).to eq(db_status.job_artifacts_failed_count)
      expect(status.job_artifacts_synced_count).to eq(db_status.job_artifacts_synced_count)
      expect(status.repositories_count).to eq(db_status.repositories_count)
      expect(status.repositories_synced_count).to eq(db_status.repositories_synced_count)
      expect(status.repositories_failed_count).to eq(db_status.repositories_failed_count)
      expect(status.last_event_id).to eq(db_status.last_event_id)
      expect(status.last_event_timestamp).to eq(db_status.last_event_timestamp)
      expect(status.cursor_last_event_id).to eq(db_status.cursor_last_event_id)
      expect(status.cursor_last_event_timestamp).to eq(db_status.cursor_last_event_timestamp)
      expect(status.last_successful_status_check_timestamp).to eq(db_status.last_successful_status_check_timestamp)
    end
  end
end
