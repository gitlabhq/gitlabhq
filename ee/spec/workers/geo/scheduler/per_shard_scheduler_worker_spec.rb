require 'spec_helper'

describe Geo::Scheduler::PerShardSchedulerWorker do
  it 'includes ApplicationWorker' do
    expect(described_class).to include_module(ApplicationWorker)
  end

  it 'includes CronjobQueue' do
    expect(described_class).to include_module(CronjobQueue)
  end

  it 'includes Gitlab::Utils::StrongMemoize' do
    expect(described_class).to include_module(::Gitlab::Utils::StrongMemoize)
  end

  it 'includes Gitlab::Geo::LogHelpers' do
    expect(described_class).to include_module(::Gitlab::Geo::LogHelpers)
  end

  it 'includes FsShards and Gitaly health checks' do
    expect(described_class::HEALTHY_SHARD_CHECKS).to include(
      Gitlab::HealthChecks::FsShardsCheck,
      Gitlab::HealthChecks::GitalyCheck
    )
  end

  describe 'instance methods' do
    subject(:per_shard_scheduler_worker) { described_class.new }

    let(:default_shard_name) { 'default' }
    let(:other_shard_name) { 'other' }
    let(:unhealthy_shard_name) { 'unhealthy' }

    let(:default_shard) { Gitlab::HealthChecks::Result.new(true, nil, shard: default_shard_name) }
    let(:other_shard) { Gitlab::HealthChecks::Result.new(true, nil, shard: other_shard_name) }
    let(:unhealthy_shard) { Gitlab::HealthChecks::Result.new(false, '14:Connect Failed', shard: unhealthy_shard_name) }

    before do
      allow(Gitlab::HealthChecks::FsShardsCheck).to receive(:readiness).and_return([default_shard, other_shard, unhealthy_shard])
      allow(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness).and_return([default_shard, other_shard, unhealthy_shard])
    end

    describe '#schedule_job' do
      it "raises a NotImplementedError exception" do
        expect do
          per_shard_scheduler_worker.schedule_job(default_shard_name)
        end.to raise_exception(NotImplementedError)
      end
    end

    describe '#ready_shards' do
      let(:ready_shards) { [[default_shard, other_shard, unhealthy_shard], [default_shard, other_shard, unhealthy_shard]] }

      it "returns an array of ready shards" do
        expect(per_shard_scheduler_worker.ready_shards).to eq(ready_shards)
      end
    end

    describe '#healthy_ready_shards' do
      let(:healthy_ready_shards) { [default_shard, other_shard] }

      it "returns an array of healthy shard names" do
        expect(per_shard_scheduler_worker.healthy_ready_shards).to eq(healthy_ready_shards)
      end
    end

    describe '#healthy_shard_names' do
      it "returns an array of healthy shard names" do
        expect(per_shard_scheduler_worker.healthy_shard_names).to eq([default_shard_name, other_shard_name])
      end
    end
  end
end
