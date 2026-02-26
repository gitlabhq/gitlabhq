# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Task do
  describe '.[]' do
    context 'when version exists' do
      it 'returns the task class for the version' do
        task_class = described_class['1.0']
        expect(task_class).to eq(ActiveContext::Task::V1_0)
      end
    end

    context 'when version does not exist' do
      it 'raises ArgumentError' do
        expect do
          described_class['9.9']
        end.to raise_error(ArgumentError, /Unknown task version/)
      end
    end
  end

  describe ActiveContext::Task::V1_0 do
    let(:mock_adapter) { double('Adapter') }
    let(:mock_executor) { double('Executor') }
    let(:task_record) { double('TaskRecord', params: { key: 'value' }, connection: nil) }

    before do
      allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
      allow(mock_adapter).to receive(:executor).and_return(mock_executor)
      allow(mock_adapter).to receive(:full_collection_name)
    end

    describe '.batched!' do
      let(:task_class) do
        stub_const('TestTaskClass', Class.new(described_class))
      end

      it 'sets batched to true' do
        task_class.batched!
        expect(task_class.batched?).to be true
      end
    end

    describe '.batched?' do
      it 'returns false by default' do
        expect(described_class.batched?).to be false
      end
    end

    describe '#initialize' do
      context 'with valid params' do
        it 'initializes with task_record' do
          task = described_class.new(task_record)
          expect(task.task_record).to eq(task_record)
        end
      end

      context 'with missing required params' do
        let(:task_with_required_params) do
          Class.new(described_class) do
            def required_params
              [:required_key]
            end
          end
        end

        it 'raises MissingParamError' do
          expect do
            task_with_required_params.new(task_record)
          end.to raise_error(ActiveContext::Task::V1_0::MissingParamError, /Missing required params/)
        end
      end
    end

    describe '#execute!' do
      it 'raises NotImplementedError' do
        task = described_class.new
        expect do
          task.execute!
        end.to raise_error(NotImplementedError, /must implement #execute!/)
      end
    end

    describe '#completed?' do
      let(:task_class) { Class.new(described_class) }

      context 'when not batched' do
        it 'returns true' do
          expect(task_class.new.completed?).to be true
        end
      end

      context 'when batched' do
        before do
          task_class.batched!
        end

        it 'raises NotImplementedError' do
          expect { task_class.new.completed? }
            .to raise_error(NotImplementedError, /must implement #completed\?/)
        end
      end
    end

    describe '#params' do
      it 'returns params from task_record' do
        task = described_class.new(task_record)
        expect(task.params).to eq({ key: 'value' })
      end

      it 'returns empty hash when task_record is nil' do
        task = described_class.new
        expect(task.params).to eq({})
      end
    end

    describe '#required_params' do
      it 'returns empty array by default' do
        task = described_class.new
        expect(task.required_params).to eq([])
      end
    end

    describe '#connection' do
      it 'returns connection from task_record' do
        task = described_class.new(task_record)
        expect(task.connection).to be_nil
      end

      it 'returns nil when task_record is nil' do
        task = described_class.new
        expect(task.connection).to be_nil
      end
    end
  end
end
