require 'spec_helper'

describe Geo::MetricsUpdateService, :geo do
  include ::EE::GeoHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }
  set(:another_secondary) { create(:geo_node) }

  subject { described_class.new }

  let(:event_date) { Time.now.utc }

  let(:data) do
    {
      success: true,
      status_message: nil,
      db_replication_lag_seconds: 0,
      repositories_count: 10,
      repositories_synced_count: 1,
      repositories_failed_count: 2,
      wikis_count: 10,
      wikis_synced_count: 2,
      wikis_failed_count: 3,
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
      last_event_date: event_date,
      cursor_last_event_id: 1,
      cursor_last_event_date: event_date,
      event_log_count: 55,
      event_log_max_id: 555,
      repository_created_max_id: 43,
      repository_updated_max_id: 132,
      repository_deleted_max_id: 23,
      repository_renamed_max_id: 11,
      repositories_changed_max_id: 109,
      lfs_object_deleted_max_id: 84,
      job_artifact_deleted_max_id: 78,
      hashed_storage_migrated_max_id: 9,
      hashed_storage_attachments_max_id: 65
    }
  end

  let(:primary_data) do
    {
      success: true,
      status_message: nil,
      repositories_count: 10,
      wikis_count: 10,
      lfs_objects_count: 100,
      job_artifacts_count: 100,
      attachments_count: 30,
      last_event_id: 2,
      last_event_date: event_date,
      event_log_count: 55,
      event_log_max_id: 555
    }
  end

  before do
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
  end

  describe '#execute' do
    before do
      request = double(success?: true, parsed_response: data.stringify_keys, code: 200)
      allow(Geo::NodeStatusFetchService).to receive(:get).and_return(request)
    end

    context 'when current node is nil' do
      before do
        stub_current_geo_node(nil)
      end

      it 'skips fetching the status' do
        expect(Geo::NodeStatusFetchService).to receive(:get).never

        subject.execute
      end
    end

    context 'when node is the primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'attempts to retrieve metrics from all nodes' do
        allow(GeoNodeStatus).to receive(:current_node_status).and_return(GeoNodeStatus.from_json(primary_data.as_json))

        subject.execute

        expect(Gitlab::Metrics.registry.get(:geo_db_replication_lag_seconds).values.count).to eq(2)
        expect(Gitlab::Metrics.registry.get(:geo_repositories).values.count).to eq(3)
        expect(Gitlab::Metrics.registry.get(:geo_repositories).get({ url: secondary.url })).to eq(10)
        expect(Gitlab::Metrics.registry.get(:geo_repositories).get({ url: another_secondary.url })).to eq(10)
        expect(Gitlab::Metrics.registry.get(:geo_repositories).get({ url: primary.url })).to eq(10)
      end

      it 'updates the GeoNodeStatus entry' do
        expect { subject.execute }.to change { GeoNodeStatus.count }.by(3)

        status = secondary.status.load_data_from_current_node

        expect(status.geo_node_id).to eq(secondary.id)
        expect(status.last_successful_status_check_at).not_to be_nil
      end

      it 'updates only the active node' do
        secondary.update_attributes(enabled: false)

        expect { subject.execute }.to change { GeoNodeStatus.count }.by(2)

        expect(another_secondary.status).not_to be_nil
      end
    end

    context 'when node is a secondary' do
      subject { described_class.new }

      before do
        stub_current_geo_node(secondary)
        allow(subject).to receive(:node_status).and_return(GeoNodeStatus.new(data))
      end

      it 'adds gauges for various metrics' do
        subject.execute

        expect(metric_value(:geo_db_replication_lag_seconds)).to eq(0)
        expect(metric_value(:geo_repositories)).to eq(10)
        expect(metric_value(:geo_repositories_synced)).to eq(1)
        expect(metric_value(:geo_repositories_failed)).to eq(2)
        expect(metric_value(:geo_wikis)).to eq(10)
        expect(metric_value(:geo_wikis_synced)).to eq(2)
        expect(metric_value(:geo_wikis_failed)).to eq(3)
        expect(metric_value(:geo_lfs_objects)).to eq(100)
        expect(metric_value(:geo_lfs_objects_synced)).to eq(50)
        expect(metric_value(:geo_lfs_objects_failed)).to eq(12)
        expect(metric_value(:geo_job_artifacts)).to eq(100)
        expect(metric_value(:geo_job_artifacts_synced)).to eq(50)
        expect(metric_value(:geo_job_artifacts_failed)).to eq(12)
        expect(metric_value(:geo_attachments)).to eq(30)
        expect(metric_value(:geo_attachments_synced)).to eq(30)
        expect(metric_value(:geo_attachments_failed)).to eq(25)
        expect(metric_value(:geo_last_event_id)).to eq(2)
        expect(metric_value(:geo_last_event_timestamp)).to eq(event_date.to_i)
        expect(metric_value(:geo_cursor_last_event_id)).to eq(1)
        expect(metric_value(:geo_cursor_last_event_timestamp)).to eq(event_date.to_i)
        expect(metric_value(:geo_last_successful_status_check_timestamp)).to be_truthy
        expect(metric_value(:geo_event_log)).to eq(55)
        expect(metric_value(:geo_event_log_max_id)).to eq(555)
        expect(metric_value(:geo_repository_created_max_id)).to eq(43)
        expect(metric_value(:geo_repository_updated_max_id)).to eq(132)
        expect(metric_value(:geo_repository_deleted_max_id)).to eq(23)
        expect(metric_value(:geo_repository_renamed_max_id)).to eq(11)
        expect(metric_value(:geo_repositories_changed_max_id)).to eq(109)
        expect(metric_value(:geo_lfs_object_deleted_max_id)).to eq(84)
        expect(metric_value(:geo_job_artifact_deleted_max_id)).to eq(78)
        expect(metric_value(:geo_hashed_storage_migrated_max_id)).to eq(9)
        expect(metric_value(:geo_hashed_storage_attachments_max_id)).to eq(65)
      end

      it 'increments a counter when metrics fail to retrieve' do
        allow(subject).to receive(:node_status).and_return(GeoNodeStatus.new(success: false))

        # Run once to get the gauge set
        subject.execute

        expect { subject.execute }.to change { metric_value(:geo_status_failed_total) }.by(1)
      end

      it 'does not create GeoNodeStatus entries' do
        expect { subject.execute }.to change { GeoNodeStatus.count }.by(0)
      end

      def metric_value(metric_name)
        Gitlab::Metrics.registry.get(metric_name)&.get({ url: secondary.url })
      end
    end
  end
end
