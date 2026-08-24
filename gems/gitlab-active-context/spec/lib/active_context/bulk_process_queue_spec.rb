# frozen_string_literal: true

RSpec.describe ActiveContext::BulkProcessQueue do
  let(:queue) { instance_double('ActiveContext::Queue', failure_queue: ActiveContext::RetryQueue) }
  let(:shard) { 0 }
  let(:redis) { instance_double(Redis) }
  let(:bulk_processor) { instance_double('ActiveContext::BulkProcessor') }
  let(:logger) { instance_double('Logger', info: nil, error: nil) }
  let(:preprocess_result) { { successful: references, failed: [], retryable: [] } }

  subject(:bulk_process_queue) { described_class.new(queue, shard) }

  before do
    allow(ActiveContext::Redis).to receive(:with_redis).and_yield(redis)
    allow(ActiveContext::BulkProcessor).to receive(:new).and_return(bulk_processor)
    allow(ActiveContext::Config).to receive(:logger).and_return(logger)
    allow(ActiveContext::RetryQueue).to receive(:push)
    allow(ActiveContext::SecondRetryQueue).to receive(:push)
    allow(ActiveContext::ThirdRetryQueue).to receive(:push)
    allow(ActiveContext::FourthRetryQueue).to receive(:push)
    allow(ActiveContext::DeadQueue).to receive(:push)
    allow(bulk_processor).to receive(:process)
    allow(bulk_processor).to receive(:flush).and_return([])
    allow(queue).to receive_messages(preprocess_options: {}, queue_name: 'code')
  end

  describe '#process' do
    let(:specs) { [['spec1', 1], ['spec2', 2]] }
    let(:reference_class) { class_double("ActiveContext::Reference").as_stubbed_const }
    let(:references) { [instance_double('ActiveContext::Reference'), instance_double('ActiveContext::Reference')] }

    before do
      allow(queue).to receive(:each_queued_items_by_shard).and_yield(shard, specs)
      allow(queue).to receive(:redis_set_key).and_return('redis_set_key')
      allow(queue).to receive(:push)
      allow(bulk_process_queue).to receive(:deserialize_all).and_return(references)
      allow(redis).to receive(:zremrangebyscore)
      allow(references).to receive(:group_by).and_return({ reference_class => references })
      allow(reference_class).to receive(:preprocess_references).and_return(preprocess_result)
    end

    it 'builds the bulk processor with the queue name' do
      bulk_process_queue.process(redis)

      expect(ActiveContext::BulkProcessor).to have_received(:new).with(queue_name: 'code')
    end

    it 'processes specs and flushes the bulk processor' do
      expect(bulk_processor).to receive(:process).twice
      expect(bulk_processor).to receive(:flush)

      bulk_process_queue.process(redis)
    end

    it 'fetches only items that are due for processing' do
      expect(queue).to receive(:each_queued_items_by_shard)
        .with(redis, shards: [shard], due_only: true)
        .and_yield(shard, specs)

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
      let(:preprocess_result) { { successful: references, failed: ['preprocess_failed_ref'], retryable: [] } }

      before do
        allow(bulk_processor).to receive(:flush).and_return(failures)
      end

      it 'adds failures to the retry queue' do
        combined_failures = ['preprocess_failed_ref'] + failures
        expect(ActiveContext).to receive(:track!).with(combined_failures, queue: ActiveContext::RetryQueue)

        bulk_process_queue.process(redis)
      end

      it 'returns the correct count of processed specs and failures' do
        expect(bulk_process_queue.process(redis)).to eq([2, 2])
      end

      context 'when the queue is a retry chain stage' do
        where(:stage, :next_stage) do
          [
            [ActiveContext::RetryQueue, ActiveContext::SecondRetryQueue],
            [ActiveContext::SecondRetryQueue, ActiveContext::ThirdRetryQueue],
            [ActiveContext::ThirdRetryQueue, ActiveContext::FourthRetryQueue],
            [ActiveContext::FourthRetryQueue, ActiveContext::DeadQueue]
          ]
        end

        with_them do
          let(:queue) { stage }

          it 'adds failures to the next stage of the chain' do
            combined_failures = ['preprocess_failed_ref'] + failures
            expect(ActiveContext).to receive(:track!).with(combined_failures, queue: next_stage)

            bulk_process_queue.process(redis)
          end

          it 'returns the correct count of processed specs and failures' do
            expect(bulk_process_queue.process(redis)).to eq([2, 2])
          end
        end
      end
    end

    context 'when there are retryable errors' do
      let(:retryable_refs) { %w[retryable_ref_1 retryable_ref_2] }
      let(:preprocess_result) { { successful: references, failed: [], retryable: retryable_refs } }

      it 'adds retryable refs back to the same queue' do
        expect(ActiveContext).to receive(:track!).with(retryable_refs, queue: queue)

        bulk_process_queue.process(redis)
      end

      it 'returns the correct count excluding retryable refs' do
        expect(bulk_process_queue.process(redis)).to eq([2, 0])
      end

      context 'when there are both failures and retryable errors' do
        let(:failures) { ['failed_spec'] }
        let(:preprocess_result) do
          { successful: references, failed: ['preprocess_failed_ref'], retryable: retryable_refs }
        end

        before do
          allow(bulk_processor).to receive(:flush).and_return(failures)
        end

        it 'routes failures to retry queue and retryable refs to origin queue' do
          combined_failures = ['preprocess_failed_ref'] + failures
          expect(ActiveContext).to receive(:track!).with(combined_failures, queue: ActiveContext::RetryQueue)
          expect(ActiveContext).to receive(:track!).with(retryable_refs, queue: queue)

          bulk_process_queue.process(redis)
        end

        it 'returns the correct total count excluding retryable refs' do
          expect(bulk_process_queue.process(redis)).to eq([2, 2])
        end
      end
    end

    it 'logs the indexing completion with relevant information' do
      expect(logger).to receive(:info).with(
        hash_including(
          'class_name' => described_class.name,
          'message' => 'bulk_indexing_end',
          'meta.indexing.redis_set' => 'redis_set_key',
          'meta.indexing.refs_count' => 2,
          'meta.indexing.first_score' => 1,
          'meta.indexing.last_score' => 2,
          'meta.indexing.failures_count' => 0,
          'meta.indexing.retryable_count' => 0,
          'meta.indexing.bulk_execution_duration_s' => kind_of(Numeric),
          'meta.indexing.bulk_execution_duration_per_ref_ms' => kind_of(Numeric)
        )
      )

      bulk_process_queue.process(redis)
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
