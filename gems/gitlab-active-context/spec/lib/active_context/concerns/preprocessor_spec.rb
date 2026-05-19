# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Concerns::Preprocessor do
  let(:test_ref_class) do
    Class.new do
      extend ActiveContext::Concerns::Preprocessor

      def self.preprocessors
        @preprocessors ||= []
      end
    end
  end

  describe '.add_preprocessor' do
    it 'adds a preprocessor to the list' do
      test_ref_class.add_preprocessor :test do |refs|
        { successful: refs, failed: [] }
      end

      expect(test_ref_class.preprocessors.length).to eq(1)
      expect(test_ref_class.preprocessors.first[:name]).to eq(:test)
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

    context 'with preprocessor that returns retryable refs' do
      before do
        test_ref_class.add_preprocessor :with_retryable do |refs|
          { successful: [refs[0]], failed: [refs[1]], retryable: [refs[2]] }
        end
      end

      it 'includes retryable refs in result' do
        result = test_ref_class.preprocess([ref1, ref2, test_ref_class.new])

        expect(result[:successful]).to eq([ref1])
        expect(result[:failed]).to eq([ref2])
        expect(result[:retryable].length).to eq(1)
      end
    end

    context 'with preprocessor that does not return retryable key' do
      before do
        test_ref_class.add_preprocessor :without_retryable do |refs|
          { successful: refs, failed: [] }
        end
      end

      it 'handles missing retryable key gracefully' do
        result = test_ref_class.preprocess(refs)

        expect(result[:successful]).to eq(refs)
        expect(result[:failed]).to be_empty
        expect(result[:retryable]).to be_empty
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
        expect(result[:retryable]).to be_empty
      end
    end

    context 'when block raises standard error' do
      it 'returns all refs as failed' do
        result = test_ref_class.with_batch_handling(refs) do
          raise StandardError, "some error"
        end

        expect(result[:successful]).to be_empty
        expect(result[:failed]).to eq(refs)
        expect(result[:retryable]).to be_empty
        expect(ActiveContext::Logger).to have_received(:retryable_exception)
      end
    end

    context 'when block raises infinite retry error type' do
      let(:custom_error) { Class.new(StandardError) }

      it 'returns all refs as retryable' do
        result = test_ref_class.with_batch_handling(refs, infinite_retry_error_types: [custom_error]) do
          raise custom_error, "transient error"
        end

        expect(result[:successful]).to be_empty
        expect(result[:failed]).to be_empty
        expect(result[:retryable]).to eq(refs)
        expect(ActiveContext::Logger).to have_received(:retryable_exception)
      end
    end

    context 'with multiple infinite retry error types' do
      let(:error1) { Class.new(StandardError) }
      let(:error2) { Class.new(StandardError) }

      it 'catches any of the specified error types as retryable' do
        result1 = test_ref_class.with_batch_handling(refs, infinite_retry_error_types: [error1, error2]) do
          raise error1
        end

        result2 = test_ref_class.with_batch_handling(refs, infinite_retry_error_types: [error1, error2]) do
          raise error2
        end

        expect(result1[:retryable]).to eq(refs)
        expect(result2[:retryable]).to eq(refs)
      end
    end

    context 'with custom error_types and infinite_retry_error_types' do
      let(:retriable_error) { Class.new(StandardError) }
      let(:custom_error) { Class.new(StandardError) }

      it 'catches infinite retry errors before standard errors' do
        result = test_ref_class.with_batch_handling(
          refs,
          error_types: [custom_error],
          infinite_retry_error_types: [retriable_error]
        ) do
          raise retriable_error
        end

        expect(result[:retryable]).to eq(refs)
        expect(result[:failed]).to be_empty
      end

      it 'catches custom errors as failed when not in infinite retry list' do
        result = test_ref_class.with_batch_handling(
          refs,
          error_types: [custom_error],
          infinite_retry_error_types: [retriable_error]
        ) do
          raise custom_error
        end

        expect(result[:failed]).to eq(refs)
        expect(result[:retryable]).to be_empty
      end
    end

    context 'with empty refs' do
      it 'returns empty result without executing block' do
        block_executed = false

        result = test_ref_class.with_batch_handling([], infinite_retry_error_types: [StandardError]) do
          block_executed = true
        end

        expect(block_executed).to be(false)
        expect(result[:successful]).to be_empty
        expect(result[:failed]).to be_empty
        expect(result[:retryable]).to be_empty
      end
    end
  end
end
