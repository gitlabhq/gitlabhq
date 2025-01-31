# frozen_string_literal: true

RSpec.describe ActiveContext::BulkProcessQueue do
  let(:queue) { instance_double('ActiveContext::Queue') }
  let(:shard) { 0 }
  let(:redis) { instance_double(Redis) }
  let(:bulk_processor) { instance_double('ActiveContext::BulkProcessor') }
  let(:logger) { instance_double('Logger', info: nil, error: nil) }

  subject(:bulk_process_queue) { described_class.new(queue, shard) }

  before do
    allow(ActiveContext::Redis).to receive(:with_redis).and_yield(redis)
    allow(ActiveContext::BulkProcessor).to receive(:new).and_return(bulk_processor)
    allow(ActiveContext::Config).to receive(:logger).and_return(logger)
    allow(bulk_processor).to receive(:process)
    allow(bulk_processor).to receive(:flush).and_return([])
  end

  describe '#process' do
    let(:specs) { [['spec1', 1], ['spec2', 2]] }
    let(:reference_class) { class_double("ActiveContext::Reference", preload_refs: nil).as_stubbed_const }
    let(:references) { [instance_double('ActiveContext::Reference'), instance_double('ActiveContext::Reference')] }

    before do
      allow(queue).to receive(:each_queued_items_by_shard).and_yield(shard, specs)
      allow(queue).to receive(:redis_set_key).and_return('redis_set_key')
      allow(queue).to receive(:push)
      allow(bulk_process_queue).to receive(:deserialize_all).and_return(references)
      allow(redis).to receive(:zremrangebyscore)
      allow(references).to receive(:group_by).and_return({ reference_class => references })
      allow(reference_class).to receive(:preload_refs)
      allow(ActiveContext::Reference).to receive(:preload).and_return(references)
    end

    it 'processes specs and flushes the bulk processor' do
      expect(bulk_processor).to receive(:process).twice
      expect(bulk_processor).to receive(:flush)

      bulk_process_queue.process(redis)
    end

    it 'removes processed items from Redis' do
      expect(redis).to receive(:zremrangebyscore).with('redis_set_key', 1, 2)

      bulk_process_queue.process(redis)
    end

    it 'returns the count of processed specs and failures' do
      expect(bulk_process_queue.process(redis)).to eq([2, 0])
    end

    context 'when there are failures' do
      let(:failures) { ['failed_spec'] }

      before do
        allow(bulk_processor).to receive(:flush).and_return(failures)
      end

      it 're-enqueues failures' do
        expect(ActiveContext).to receive(:track!).with(failures, queue: queue)

        bulk_process_queue.process(redis)
      end

      it 'returns the correct count of processed specs and failures' do
        expect(bulk_process_queue.process(redis)).to eq([2, 1])
      end
    end

    context 'when specs are empty' do
      let(:specs) { [] }

      it 'returns [0, 0] without processing' do
        expect(bulk_processor).not_to receive(:process)
        expect(bulk_process_queue.process(redis)).to eq([0, 0])
      end
    end
  end
end
