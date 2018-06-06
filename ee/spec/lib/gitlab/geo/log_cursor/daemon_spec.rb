require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon, :postgresql, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

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
      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.not_to receive(:run_once!)
      expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain_with_ttl).and_return({ ttl: 1, uuid: false })

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
        expect(daemon).to receive(:handle_events).with(batch)

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
        allow(Gitlab::Geo::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(true)
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

      it 'does not replay events for projects that do not belong to selected shards to replicate' do
        secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project.id, anything)

        daemon.run_once!
      end
    end
  end
end
