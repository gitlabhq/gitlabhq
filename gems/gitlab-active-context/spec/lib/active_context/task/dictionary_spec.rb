# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Task::Dictionary do
  before do
    described_class.reset!
  end

  describe '.find_by_name' do
    context 'when task class exists' do
      it 'loads and returns the task class' do
        task = described_class.find_by_name('String')
        expect(task).to eq(String)
      end
    end

    context 'when task class does not exist' do
      it 'raises InvalidTaskNameError' do
        expect do
          described_class.find_by_name('NonExistentTask')
        end.to raise_error(described_class::InvalidTaskNameError)
      end
    end
  end

  describe '.reset!' do
    it 'resets the instance' do
      instance1 = described_class.instance
      described_class.find_by_name('String')
      described_class.reset!
      instance2 = described_class.instance

      expect(instance1.object_id).not_to eq(instance2.object_id)
    end
  end
end
