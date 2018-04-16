require 'spec_helper'

describe Geo::Scheduler::SchedulerWorker, :geo do
  subject { described_class.new }

  it 'includes ::Gitlab::Geo::LogHelpers' do
    expect(described_class).to include_module(::Gitlab::Geo::LogHelpers)
  end

  it 'needs many other specs'

  describe '#take_batch' do
    let(:a) { [[2, :lfs], [3, :lfs]] }
    let(:b) { [] }
    let(:c) { [[3, :job_artifact], [8, :job_artifact], [9, :job_artifact]] }

    context 'without batch_size' do
      it 'returns a batch of jobs' do
        expect(subject).to receive(:db_retrieve_batch_size).and_return(4)

        expect(subject.send(:take_batch, a, b, c)).to eq([
          [3, :job_artifact],
          [2, :lfs],
          [8, :job_artifact],
          [3, :lfs]
        ])
      end
    end

    context 'with batch_size' do
      it 'returns a batch of jobs' do
        expect(subject.send(:take_batch, a, b, c, batch_size: 2)).to eq([
          [3, :job_artifact],
          [2, :lfs]
        ])
      end
    end
  end

  describe '#interleave' do
    # Notice ties are resolved by taking the "first" tied element
    it 'interleaves 2 arrays' do
      a = %w{1 2 3}
      b = %w{A B C}
      expect(subject.send(:interleave, a, b)).to eq(%w{1 A 2 B 3 C})
    end

    # Notice there are no ties in this call
    it 'interleaves 2 arrays with a longer second array' do
      a = %w{1 2}
      b = %w{A B C}
      expect(subject.send(:interleave, a, b)).to eq(%w{A 1 B 2 C})
    end

    it 'interleaves 2 arrays with a longer first array' do
      a = %w{1 2 3}
      b = %w{A B}
      expect(subject.send(:interleave, a, b)).to eq(%w{1 A 2 B 3})
    end

    it 'interleaves 3 arrays' do
      a = %w{1 2 3}
      b = %w{A B C}
      c = %w{i ii iii}
      expect(subject.send(:interleave, a, b, c)).to eq(%w{1 A i 2 B ii 3 C iii})
    end

    it 'interleaves 3 arrays of unequal length' do
      a = %w{1 2}
      b = %w{A}
      c = %w{i ii iii iiii}
      expect(subject.send(:interleave, a, b, c)).to eq(%w{i 1 ii A iii 2 iiii})
    end
  end
end
