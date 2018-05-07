require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::RepositoriesChangedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  set(:secondary) { create(:geo_node) }
  let(:repositories_changed_event) { create(:geo_repositories_changed_event, geo_node: secondary) }
  let(:event_log) { create(:geo_event_log, repositories_changed_event: repositories_changed_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

  subject { described_class.new(repositories_changed_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)
  end

  describe '#process' do
    it 'schedules a GeoRepositoryDestroyWorker when event node is the current node' do
      expect(Geo::RepositoriesCleanUpWorker).to receive(:perform_in).with(within(5.minutes).of(1.hour), secondary.id)

      subject.process
    end

    it 'does not schedule a GeoRepositoryDestroyWorker when event node is not the current node' do
      stub_current_geo_node(build(:geo_node))

      expect(Geo::RepositoriesCleanUpWorker).not_to receive(:perform_in)

      subject.process
    end
  end
end
