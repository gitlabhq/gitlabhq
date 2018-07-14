require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon, :postgresql, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  let(:options) { {} }

  subject(:daemon) { described_class.new(options) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)

    allow(daemon).to receive(:trap_signals)
    allow(daemon).to receive(:arbitrary_sleep).and_return(0.1)
  end

  describe '#run!' do
    it 'traps signals' do
      is_expected.to receive(:exit?).and_return(true)
      is_expected.to receive(:trap_signals)

      daemon.run!
    end

    it 'delegates to #run_once! in a loop' do
      is_expected.to receive(:exit?).and_return(false, false, false, true)
      is_expected.to receive(:run_once!).twice

      daemon.run!
    end

    it 'skips execution if cannot achieve a lease' do
      lease = stub_exclusive_lease_taken('geo_log_cursor_processed')

      allow(lease).to receive(:try_obtain_with_ttl).and_return({ ttl: 1, uuid: false })
      allow(lease).to receive(:same_uuid?).and_return(false)
      allow(Gitlab::Geo::LogCursor::Lease).to receive(:exclusive_lease).and_return(lease)

      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.not_to receive(:run_once!)

      daemon.run!
    end

    it 'skips execution if not a Geo node' do
      stub_current_geo_node(nil)

      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.to receive(:sleep).with(1.minute)
      is_expected.not_to receive(:run_once!)

      daemon.run!
    end

    it 'skips execution if the current node is a primary' do
      stub_current_geo_node(primary)

      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.to receive(:sleep).with(1.minute)
      is_expected.not_to receive(:run_once!)

      daemon.run!
    end
  end

  describe '#run_once!' do
    context 'with some event logs' do
      let(:project) { create(:project) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let(:batch) { [event_log] }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'handles events' do
        expect(daemon).to receive(:handle_events).with(batch, anything)

        daemon.run_once!
      end
    end

    context 'when node has namespace restrictions' do
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }
      let(:project) { create(:project, group: group_1) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let!(:registry) { create(:geo_project_registry, :synced, project: project) }

      before do
        allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(true)
        allow(Gitlab::Geo::Logger).to receive(:info).and_call_original
      end

      it 'replays events for projects that belong to selected namespaces to replicate' do
        secondary.update!(namespaces: [group_1])

        expect(Geo::ProjectSyncWorker).to receive(:perform_async).with(project.id, anything).once

        daemon.run_once!
      end

      it 'does not replay events for projects that do not belong to selected namespaces to replicate' do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [group_2])

        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project.id, anything)

        daemon.run_once!
      end

      it "logs a message if an event was skipped" do
        updated_event = create(:geo_repository_updated_event, project: project)
        new_event = create(:geo_event_log, id: event_log.id + 2, repository_updated_event: updated_event)

        expect(Gitlab::Geo::Logger).to receive(:info)
                                        .with(hash_including(
                                                class: 'Gitlab::Geo::LogCursor::Daemon',
                                                message: 'Event log gap',
                                                previous_event_log_id: event_log.id,
                                                event_log_id: new_event.id))

        daemon.run_once!

        expect(::Geo::EventLogState.last_processed.id).to eq(new_event.id)

        # Test that the cursor picks up from the last stored ID
        third_event = create(:geo_event_log, id: new_event.id + 3, repository_updated_event: updated_event)

        expect(Gitlab::Geo::Logger).to receive(:info)
                                        .with(hash_including(
                                                class: 'Gitlab::Geo::LogCursor::Daemon',
                                                message: 'Event log gap',
                                                previous_event_log_id: new_event.id,
                                                event_log_id: third_event.id))

        daemon.run_once!
      end

      it "logs a message if an associated event can't be found" do
        new_event = create(:geo_event_log)

        expect(Gitlab::Geo::Logger).to receive(:warn)
                                        .with(hash_including(
                                                class: 'Gitlab::Geo::LogCursor::Daemon',
                                                message: 'Unknown event',
                                                event_log_id: new_event.id))

        daemon.run_once!

        expect(::Geo::EventLogState.last_processed.id).to eq(new_event.id)
      end

      it 'logs a message for skipped events' do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [group_2])

        expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(
                                                             :pid,
                                                             :cursor_delay_s,
                                                             message: 'Skipped event',
                                                             class: 'Gitlab::Geo::LogCursor::Daemon',
                                                             event_log_id: event_log.id,
                                                             event_id: repository_updated_event.id,
                                                             event_type: 'Geo::RepositoryUpdatedEvent',
                                                             project_id: project.id))

        daemon.run_once!
      end

      it 'does not replay events for projects that do not belong to selected shards to replicate' do
        secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project.id, anything)

        daemon.run_once!
      end
    end
  end
end
