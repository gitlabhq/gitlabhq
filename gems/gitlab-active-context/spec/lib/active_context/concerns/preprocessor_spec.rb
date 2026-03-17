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
  end
end
