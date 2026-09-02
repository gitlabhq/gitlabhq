# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Concerns::Preprocessor, :aggregate_failures do
  let(:test_ref_class) do
    klass = Class.new do
      extend ActiveContext::Concerns::Preprocessor

      def self.preprocessors
        @preprocessors ||= []
      end
    end

    stub_const('TestPreprocessorReferenceClass', klass)
  end

  describe '.add_preprocessor' do
    it 'adds a preprocessor to the list' do
      test_ref_class.add_preprocessor :test do |refs|
        { successful: refs, failed: [] }
      end

      expect(test_ref_class.preprocessors.length).to eq(1)
      expect(test_ref_class.preprocessors.first[:name]).to eq(:test)
    end

    context 'with preprocessors added conditionally' do
      before do
        test_ref_class.add_preprocessor :test do |refs|
          { successful: refs, failed: [] }
        end

        test_ref_class.add_preprocessor(
          :conditional_false,
          should_run: -> { 1.is_a?(String) }
        ) do |refs|
          { successful: refs, failed: [] }
        end

        test_ref_class.add_preprocessor(
          :conditional_true,
          should_run: -> { "a".is_a?(String) }
        ) do |refs|
          { successful: refs, failed: [] }
        end
      end

      it 'adds all preprocessors and correctly evaluates eligible preprocessors' do
        expect(test_ref_class.preprocessors.length).to eq(3)
        expect(test_ref_class.preprocessors.pluck(:name))
          .to eq([:test, :conditional_false, :conditional_true])

        expect(test_ref_class.eligible_preprocessors.length).to eq(2)
        expect(test_ref_class.eligible_preprocessors.pluck(:name))
          .to eq([:test, :conditional_true])
      end
    end
  end

  describe '.preprocess' do
    let(:ref1) { test_ref_class.new }
    let(:ref2) { test_ref_class.new }
    let(:refs) { [ref1, ref2] }

    context 'with single preprocessor' do
      before do
        test_ref_class.add_preprocessor :process do |refs|
          { successful: refs, failed: [] }
        end
      end

      it 'calls the preprocessor block with refs' do
        result = test_ref_class.preprocess(refs)

        expect(result[:successful]).to eq(refs)
        expect(result[:failed]).to be_empty
      end
    end

    context 'with multiple preprocessors' do
      before do
        test_ref_class.add_preprocessor :first do |refs|
          { successful: refs, failed: [] }
        end

        test_ref_class.add_preprocessor :second do |refs|
          { successful: refs, failed: [] }
        end
      end

      it 'chains preprocessors in order' do
        result = test_ref_class.preprocess(refs)

        expect(result[:successful]).to eq(refs)
        expect(result[:failed]).to be_empty
      end
    end

    context 'with conditional preprocessors' do
      let(:test_ref_class) do
        Class.new do
          extend ActiveContext::Concerns::Preprocessor

          def self.preprocessors
            @preprocessors ||= []
          end

          def self.first_preprocessor(refs)
            { successful: refs, failed: [] }
          end

          def self.second_preprocessor(_refs)
            nil
          end

          def self.third_preprocessor(refs)
            { successful: refs, failed: [] }
          end

          add_preprocessor :first do |refs|
            first_preprocessor(refs)
          end

          add_preprocessor(
            :second,
            should_run: -> { 1.is_a?(String) }
          ) do |refs|
            second_preprocessor(refs)
          end

          add_preprocessor(
            :third,
            should_run: -> { "a".is_a?(String) }
          ) do |refs|
            third_preprocessor(refs)
          end
        end
      end

      it 'chains preprocessors in order' do
        expect(test_ref_class).not_to receive(:second_preprocessor)

        expect(test_ref_class).to receive(:first_preprocessor).ordered.and_call_original
        expect(test_ref_class).to receive(:third_preprocessor).ordered.and_call_original

        result = test_ref_class.preprocess(refs)

        expect(result[:successful]).to eq(refs)
        expect(result[:failed]).to be_empty
      end
    end

    context 'with preprocessor that fails some refs' do
      before do
        test_ref_class.add_preprocessor :filter do |refs|
          successful = refs.select { |r| r.object_id.even? }
          failed = refs.reject { |r| r.object_id.even? }
          { successful: successful, failed: failed }
        end
      end

      it 'removes failed refs from subsequent preprocessors' do
        result = test_ref_class.preprocess(refs)

        expect(result[:successful].length + result[:failed].length).to eq(2)
      end
    end

    context 'with options passed to preprocess' do
      let(:call_log) { [] }

      before do
        test_ref_class.add_preprocessor :with_options do |refs, next_model_only: false|
          call_log << { next_model_only: next_model_only }
          { successful: refs, failed: [] }
        end
      end

      it 'passes options to preprocessor blocks' do
        test_ref_class.preprocess(refs, next_model_only: true)

        expect(call_log).to include({ next_model_only: true })
      end

      it 'defaults options to false when not provided' do
        test_ref_class.preprocess(refs)

        expect(call_log).to include({ next_model_only: false })
      end
    end

    context 'with multiple preprocessors and options' do
      let(:call_log) { [] }

      before do
        test_ref_class.add_preprocessor :first do |refs, next_model_only: false|
          call_log << { stage: 'first', next_model_only: next_model_only }
          { successful: refs, failed: [] }
        end

        test_ref_class.add_preprocessor :second do |refs, next_model_only: false|
          call_log << { stage: 'second', next_model_only: next_model_only }
          { successful: refs, failed: [] }
        end
      end

      it 'passes options through the entire chain' do
        test_ref_class.preprocess(refs, next_model_only: true)

        expect(call_log).to include({ stage: 'first', next_model_only: true })
        expect(call_log).to include({ stage: 'second', next_model_only: true })
      end
    end
  end

  describe '.with_batch_handling' do
    let(:ref1) { double('ref1', serialize: 'ref:1') }
    let(:ref2) { double('ref2', serialize: 'ref:2') }
    let(:refs) { [ref1, ref2] }

    before do
      allow(ActiveContext::Logger).to receive(:retryable_exception)
    end

    context 'when block succeeds' do
      it 'returns all refs as successful' do
        result = test_ref_class.with_batch_handling(refs) do
          # success
        end

        expect(result[:successful]).to eq(refs)
        expect(result[:failed]).to be_empty
      end
    end

    context 'when block raises standard error' do
      it 'returns all refs as failed' do
        result = test_ref_class.with_batch_handling(refs) do
          raise StandardError, "some error"
        end

        expect(result[:successful]).to be_empty
        expect(result[:failed]).to eq(refs)

        expect(ActiveContext::Logger).to have_received(:retryable_exception).with(
          instance_of(StandardError),
          class_name: 'TestPreprocessorReferenceClass',
          queue_name: nil,
          preprocessor: nil,
          refs_count: 2,
          refs_sample: ['ref:1', 'ref:2']
        )
      end

      context 'when queue_name and preprocessor are specified' do
        it 'includes queue_name and preprocessor in the logged exception' do
          test_ref_class.with_batch_handling(refs, queue_name: 'test_queue', preprocessor: 'test_preprocessor') do
            raise StandardError, "some error"
          end

          expect(ActiveContext::Logger).to have_received(:retryable_exception).with(
            instance_of(StandardError),
            class_name: 'TestPreprocessorReferenceClass',
            queue_name: 'test_queue',
            preprocessor: 'test_preprocessor',
            refs_count: 2,
            refs_sample: ['ref:1', 'ref:2']
          )
        end
      end

      context 'when the batch is larger than the logged sample size' do
        let(:refs) { Array.new(12) { |i| double("ref#{i}", serialize: "ref:#{i}") } }

        it 'logs the full count and a capped sample' do
          test_ref_class.with_batch_handling(refs) do
            raise StandardError, "some error"
          end

          expect(ActiveContext::Logger).to have_received(:retryable_exception).with(
            instance_of(StandardError),
            class_name: 'TestPreprocessorReferenceClass',
            queue_name: nil,
            preprocessor: nil,
            refs_count: 12,
            refs_sample: %w[ref:0 ref:1 ref:2 ref:3 ref:4 ref:5 ref:6 ref:7 ref:8 ref:9]
          )
        end
      end
    end

    context 'with custom error_types' do
      let(:custom_error) { Class.new(StandardError) }

      it 'catches custom errors as failed' do
        result = test_ref_class.with_batch_handling(refs, error_types: [custom_error]) do
          raise custom_error
        end

        expect(result[:failed]).to eq(refs)
      end
    end

    context 'with empty refs' do
      it 'returns empty result without executing block' do
        block_executed = false

        result = test_ref_class.with_batch_handling([]) do
          block_executed = true
        end

        expect(block_executed).to be(false)
        expect(result[:successful]).to be_empty
        expect(result[:failed]).to be_empty
      end
    end
  end

  describe '.with_per_ref_handling' do
    let(:ref1) { double('ref1', serialize: 'ref:1', identifier: 'id:1') }
    let(:ref2) { double('ref2', serialize: 'ref:2', identifier: 'id:2') }
    let(:ref3) { double('ref3', serialize: 'ref:3', identifier: 'id:3') }
    let(:refs) { [ref1, ref2, ref3] }

    before do
      allow(ActiveContext::Logger).to receive(:retryable_exception)
      allow(ActiveContext::Logger).to receive(:skippable_exception)
    end

    context 'when block succeeds for all refs' do
      it 'returns all refs as successful' do
        result = test_ref_class.with_per_ref_handling(refs) do |ref|
          # success
        end

        expect(result[:successful]).to eq(refs)
        expect(result[:failed]).to be_empty
      end
    end

    context 'when block raises StandardError for some refs' do
      it 'returns failed refs and successful refs' do
        result = test_ref_class.with_per_ref_handling(refs) do |ref|
          raise StandardError, "error" if [ref2, ref3].include?(ref)
        end

        expect(result[:successful]).to eq([ref1])
        expect(result[:failed]).to eq([ref2, ref3])

        expect(ActiveContext::Logger).to have_received(:retryable_exception).with(
          instance_of(StandardError),
          class_name: 'TestPreprocessorReferenceClass',
          queue_name: nil,
          preprocessor: nil,
          reference: 'ref:2',
          reference_id: 'id:2'
        ).ordered

        expect(ActiveContext::Logger).to have_received(:retryable_exception).with(
          instance_of(StandardError),
          class_name: 'TestPreprocessorReferenceClass',
          queue_name: nil,
          preprocessor: nil,
          reference: 'ref:3',
          reference_id: 'id:3'
        ).ordered
      end

      context 'when queue_name and preprocessor are specified' do
        it 'includes queue_name in the logged exception' do
          result = test_ref_class.with_per_ref_handling(
            refs,
            queue_name: 'test_queue',
            preprocessor: 'test_preprocessor') do |ref|
            raise StandardError, "error" if ref == ref1
          end

          expect(result[:successful]).to eq([ref2, ref3])
          expect(result[:failed]).to eq([ref1])

          expect(ActiveContext::Logger).to have_received(:retryable_exception).with(
            instance_of(StandardError),
            class_name: 'TestPreprocessorReferenceClass',
            queue_name: 'test_queue',
            preprocessor: 'test_preprocessor',
            reference: 'ref:1',
            reference_id: 'id:1'
          )
        end
      end
    end

    context 'when block raises skip error for some refs' do
      let(:skip_error) { Class.new(StandardError) }

      it 'removes affected refs from the process and logs skippable exception' do
        result = test_ref_class.with_per_ref_handling(refs, skip_error_types: [skip_error]) do |ref|
          raise skip_error, "skip this" if ref == ref1
        end

        expect(result[:successful]).to eq([ref2, ref3])
        expect(result[:failed]).to be_empty

        expect(ActiveContext::Logger).to have_received(:skippable_exception).with(
          instance_of(skip_error),
          class_name: 'TestPreprocessorReferenceClass',
          queue_name: nil,
          preprocessor: nil,
          reference: 'ref:1',
          reference_id: 'id:1'
        )
      end

      context 'when queue_name and preprocessor are specified' do
        it 'includes queue_name in the logged exception' do
          result = test_ref_class.with_per_ref_handling(
            refs,
            skip_error_types: [skip_error],
            queue_name: 'test_queue',
            preprocessor: 'test_preprocessor') do |ref|
            raise skip_error, "skip this" if ref == ref1
          end

          expect(result[:successful]).to eq([ref2, ref3])
          expect(result[:failed]).to be_empty

          expect(ActiveContext::Logger).to have_received(:skippable_exception).with(
            instance_of(skip_error),
            class_name: 'TestPreprocessorReferenceClass',
            queue_name: 'test_queue',
            preprocessor: 'test_preprocessor',
            reference: 'ref:1',
            reference_id: 'id:1'
          )
        end
      end
    end

    context 'with custom retry_error_types' do
      let(:custom_error) { Class.new(StandardError) }

      it 'catches only specified error types as failed' do
        result = test_ref_class.with_per_ref_handling(refs, retry_error_types: [custom_error]) do |ref|
          raise custom_error, "custom error" if ref == ref1
        end

        expect(result[:successful]).to eq([ref2, ref3])
        expect(result[:failed]).to eq([ref1])
      end

      context 'when there is an error other than the specified type' do
        def run_per_ref_handling
          test_ref_class.with_per_ref_handling(refs, retry_error_types: [custom_error]) do |ref|
            raise custom_error, "custom error" if ref == ref1
            raise StandardError, "standard error" if ref == ref2
          end
        end

        it 'raises an error' do
          expect { run_per_ref_handling }.to raise_error(StandardError, 'standard error')
        end
      end
    end

    context 'with empty refs' do
      it 'returns empty result without executing block' do
        block_executed = false

        result = test_ref_class.with_per_ref_handling([]) do |_ref|
          block_executed = true
        end

        expect(block_executed).to be(false)
        expect(result[:successful]).to be_empty
        expect(result[:failed]).to be_empty
      end
    end
  end
end
