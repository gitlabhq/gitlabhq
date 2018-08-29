require 'spec_helper'

describe Gitlab::SidekiqCluster do
  describe '.trap_signals' do
    it 'traps the given signals' do
      expect(described_class).to receive(:trap).ordered.with(:INT)
      expect(described_class).to receive(:trap).ordered.with(:HUP)

      described_class.trap_signals(%i(INT HUP))
    end
  end

  describe '.trap_terminate' do
    it 'traps the termination signals' do
      expect(described_class).to receive(:trap_signals)
        .with(described_class::TERMINATE_SIGNALS)

      described_class.trap_terminate { }
    end
  end

  describe '.trap_forward' do
    it 'traps the signals to forward' do
      expect(described_class).to receive(:trap_signals)
        .with(described_class::FORWARD_SIGNALS)

      described_class.trap_forward { }
    end
  end

  describe '.signal' do
    it 'sends a signal to the given process' do
      allow(Process).to receive(:kill).with(:INT, 4)
      expect(described_class.signal(4, :INT)).to eq(true)
    end

    it 'returns false when the process does not exist' do
      allow(Process).to receive(:kill).with(:INT, 4).and_raise(Errno::ESRCH)
      expect(described_class.signal(4, :INT)).to eq(false)
    end
  end

  describe '.signal_processes' do
    it 'sends a signal to every thread' do
      expect(described_class).to receive(:signal).with(1, :INT)

      described_class.signal_processes([1], :INT)
    end
  end

  describe '.parse_queues' do
    it 'returns an Array containing the parsed queues' do
      expect(described_class.parse_queues(%w(foo bar,baz)))
        .to eq([%w(foo), %w(bar baz)])
    end
  end

  describe '.start' do
    it 'starts Sidekiq with the given queues and environment' do
      expect(described_class).to receive(:start_sidekiq)
        .ordered.with(%w(foo), :production, 'foo/bar', 50, dryrun: false)

      expect(described_class).to receive(:start_sidekiq)
        .ordered.with(%w(bar baz), :production, 'foo/bar', 50, dryrun: false)

      described_class.start([%w(foo), %w(bar baz)], :production, 'foo/bar', 50)
    end

    it 'starts Sidekiq with capped concurrency limits for each queue' do
      expect(described_class).to receive(:start_sidekiq)
        .ordered.with(%w(foo bar baz), :production, 'foo/bar', 2, dryrun: false)

      expect(described_class).to receive(:start_sidekiq)
        .ordered.with(%w(solo), :production, 'foo/bar', 2, dryrun: false)

      described_class.start([%w(foo bar baz), %w(solo)], :production, 'foo/bar', 2)
    end
  end

  describe '.start_sidekiq' do
    it 'starts a Sidekiq process' do
      allow(Process).to receive(:spawn).and_return(1)

      expect(described_class).to receive(:wait_async).with(1)
      expect(described_class.start_sidekiq(%w(foo), :production)).to eq(1)
    end
  end

  describe '.wait_async' do
    it 'waits for a process in a separate thread' do
      thread = described_class.wait_async(Process.spawn('true'))

      # Upon success Process.wait just returns the PID.
      expect(thread.value).to be_a_kind_of(Numeric)
    end
  end

  describe '.all_alive?' do
    it 'returns true if all processes are alive' do
      processes = [1]

      allow(described_class).to receive(:signal).with(1, 0).and_return(true)

      expect(described_class.all_alive?(processes)).to eq(true)
    end

    it 'returns false when a thread was not alive' do
      processes = [1]

      allow(described_class).to receive(:signal).with(1, 0).and_return(false)

      expect(described_class.all_alive?(processes)).to eq(false)
    end
  end

  describe '.write_pid' do
    it 'writes the PID of the current process to the given file' do
      handle = double(:handle)

      allow(File).to receive(:open).with('/dev/null', 'w').and_yield(handle)

      expect(handle).to receive(:write).with(Process.pid.to_s)

      described_class.write_pid('/dev/null')
    end
  end
end
