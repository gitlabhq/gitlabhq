# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::System do
  context 'when /proc files exist' do
    # Modified column 22 to be 1000 (starttime ticks)
    let(:proc_stat) do
      <<~SNIP
      2095 (ruby) R 0 2095 2095 34818 2095 4194560 211267 7897 2 0 287 51 10 1 20 0 5 0 1000 566210560 80885 18446744073709551615 94736211292160 94736211292813 140720919612064 0 0 0 0 0 1107394127 0 0 0 17 3 0 0 0 0 0 94736211303768 94736211304544 94736226689024 140720919619473 140720919619513 140720919619513 140720919621604 0
      SNIP
    end

    # Fixtures pulled from:
    # Linux carbon 5.3.0-7648-generic #41~1586789791~19.10~9593806-Ubuntu SMP
    # Mon Apr 13 17:50:40 UTC  x86_64 x86_64 x86_64 GNU/Linux
    let(:proc_status) do
      # most rows omitted for brevity
      <<~SNIP
      Name:       less
      VmHWM:      2468 kB
      VmRSS:      2468 kB
      RssAnon:    260 kB
      RssFile:    1024 kB
      SNIP
    end

    let(:proc_smaps_rollup) do
      # full snapshot
      <<~SNIP
      Rss:                2564 kB
      Pss:                 503 kB
      Pss_Anon:            312 kB
      Pss_File:            191 kB
      Pss_Shmem:             0 kB
      Shared_Clean:       2100 kB
      Shared_Dirty:          0 kB
      Private_Clean:       152 kB
      Private_Dirty:       312 kB
      Referenced:         2564 kB
      Anonymous:           312 kB
      LazyFree:              0 kB
      AnonHugePages:         0 kB
      ShmemPmdMapped:        0 kB
      Shared_Hugetlb:        0 kB
      Private_Hugetlb:       0 kB
      Swap:                  0 kB
      SwapPss:               0 kB
      Locked:                0 kB
      SNIP
    end

    let(:proc_limits) do
      # full snapshot
      <<~SNIP
      Limit                     Soft Limit           Hard Limit           Units
      Max cpu time              unlimited            unlimited            seconds
      Max file size             unlimited            unlimited            bytes
      Max data size             unlimited            unlimited            bytes
      Max stack size            8388608              unlimited            bytes
      Max core file size        0                    unlimited            bytes
      Max resident set          unlimited            unlimited            bytes
      Max processes             126519               126519               processes
      Max open files            1024                 1048576              files
      Max locked memory         67108864             67108864             bytes
      Max address space         unlimited            unlimited            bytes
      Max file locks            unlimited            unlimited            locks
      Max pending signals       126519               126519               signals
      Max msgqueue size         819200               819200               bytes
      Max nice priority         0                    0
      Max realtime priority     0                    0
      Max realtime timeout      unlimited            unlimited            us
      SNIP
    end

    let(:mem_info) do
      # full snapshot
      <<~SNIP
        MemTotal:       15362536 kB
        MemFree:         3403136 kB
        MemAvailable:   13044528 kB
        Buffers:          272188 kB
        Cached:          8171312 kB
        SwapCached:            0 kB
        Active:          3332084 kB
        Inactive:        6981076 kB
        Active(anon):    1603868 kB
        Inactive(anon):     9044 kB
        Active(file):    1728216 kB
        Inactive(file):  6972032 kB
        Unevictable:       18676 kB
        Mlocked:           18676 kB
        SwapTotal:             0 kB
        SwapFree:              0 kB
        Dirty:              6808 kB
        Writeback:             0 kB
        AnonPages:       1888300 kB
        Mapped:           166164 kB
        Shmem:             12932 kB
        KReclaimable:    1275120 kB
        Slab:            1495480 kB
        SReclaimable:    1275120 kB
        SUnreclaim:       220360 kB
        KernelStack:        7072 kB
        PageTables:        11936 kB
        NFS_Unstable:          0 kB
        Bounce:                0 kB
        WritebackTmp:          0 kB
        CommitLimit:     7681268 kB
        Committed_AS:    4976100 kB
        VmallocTotal:   34359738367 kB
        VmallocUsed:       25532 kB
        VmallocChunk:          0 kB
        Percpu:            23200 kB
        HardwareCorrupted:     0 kB
        AnonHugePages:    202752 kB
        ShmemHugePages:        0 kB
        ShmemPmdMapped:        0 kB
        FileHugePages:         0 kB
        FilePmdMapped:         0 kB
        CmaTotal:              0 kB
        CmaFree:               0 kB
        HugePages_Total:       0
        HugePages_Free:        0
        HugePages_Rsvd:        0
        HugePages_Surp:        0
        Hugepagesize:       2048 kB
        Hugetlb:               0 kB
        DirectMap4k:     4637504 kB
        DirectMap2M:    11087872 kB
        DirectMap1G:     2097152 kB
      SNIP
    end

    describe '.memory_usage_rss' do
      context 'without PID' do
        it "returns a hash containing RSS metrics in bytes for current process" do
          mock_existing_proc_file('/proc/self/status', proc_status)

          expect(described_class.memory_usage_rss).to eq(
            total: 2527232,
            anon: 266240,
            file: 1048576
          )
        end
      end

      context 'with PID' do
        it "returns a hash containing RSS metrics in bytes for given process" do
          mock_existing_proc_file('/proc/7/status', proc_status)

          expect(described_class.memory_usage_rss(pid: 7)).to eq(
            total: 2527232,
            anon: 266240,
            file: 1048576
          )
        end
      end
    end

    describe '.file_descriptor_count' do
      it 'returns the amount of open file descriptors' do
        expect(Dir).to receive(:glob).and_return(['/some/path', '/some/other/path'])

        expect(described_class.file_descriptor_count).to eq(2)
      end
    end

    describe '.max_open_file_descriptors' do
      it 'returns the max allowed open file descriptors' do
        mock_existing_proc_file('/proc/self/limits', proc_limits)

        expect(described_class.max_open_file_descriptors).to eq(1024)
      end
    end

    describe '.memory_usage_uss_pss' do
      context 'without PID' do
        it "returns the current process' unique and porportional set size (USS/PSS) in bytes" do
          mock_existing_proc_file('/proc/self/smaps_rollup', proc_smaps_rollup)

          # (Private_Clean (152 kB) + Private_Dirty (312 kB) + Private_Hugetlb (0 kB)) * 1024
          expect(described_class.memory_usage_uss_pss).to eq(uss: 475136, pss: 515072)
        end
      end

      context 'with PID' do
        it "returns the given process' unique and porportional set size (USS/PSS) in bytes" do
          mock_existing_proc_file('/proc/7/smaps_rollup', proc_smaps_rollup)

          # (Private_Clean (152 kB) + Private_Dirty (312 kB) + Private_Hugetlb (0 kB)) * 1024
          expect(described_class.memory_usage_uss_pss(pid: 7)).to eq(uss: 475136, pss: 515072)
        end
      end
    end

    describe '.memory_total' do
      it "returns the current process' resident set size (RSS) in bytes" do
        mock_existing_proc_file('/proc/meminfo', mem_info)

        expect(described_class.memory_total).to eq(15731236864)
      end
    end

    describe '.process_runtime_elapsed_seconds' do
      it 'returns the seconds elapsed since the process was started' do
        # sets process starttime ticks to 1000
        mock_existing_proc_file('/proc/self/stat', proc_stat)
        # system clock ticks/sec
        expect(Etc).to receive(:sysconf).with(Etc::SC_CLK_TCK).and_return(100)
        # system uptime in seconds
        expect(::Process).to receive(:clock_gettime).and_return(15)

        # uptime - (starttime_ticks / ticks_per_sec)
        expect(described_class.process_runtime_elapsed_seconds).to eq(5)
      end

      context 'when inputs are not available' do
        it 'returns 0' do
          mock_missing_proc_file
          expect(::Process).to receive(:clock_gettime).and_raise(NameError)

          expect(described_class.process_runtime_elapsed_seconds).to eq(0)
        end
      end
    end

    describe '.summary' do
      it 'contains a selection of the available fields' do
        stub_const('RUBY_DESCRIPTION', 'ruby-3.2-patch1')
        mock_existing_proc_file('/proc/self/status', proc_status)
        mock_existing_proc_file('/proc/self/smaps_rollup', proc_smaps_rollup)

        summary = described_class.summary

        expect(summary[:version]).to eq('ruby-3.2-patch1')
        expect(summary[:gc_stat].keys).to eq(GC.stat.keys)
        expect(summary[:memory_rss]).to eq(2527232)
        expect(summary[:memory_uss]).to eq(475136)
        expect(summary[:memory_pss]).to eq(515072)
        expect(summary[:time_cputime]).to be_a(Float)
        expect(summary[:time_realtime]).to be_a(Float)
        expect(summary[:time_monotonic]).to be_a(Float)
      end
    end
  end

  context 'when /proc files do not exist' do
    before do
      mock_missing_proc_file
    end

    describe '.memory_usage_rss' do
      it 'returns 0 for all components' do
        expect(described_class.memory_usage_rss).to eq(
          total: 0,
          anon: 0,
          file: 0
        )
      end
    end

    describe '.memory_usage_uss_pss' do
      it "returns 0 for all components" do
        expect(described_class.memory_usage_uss_pss).to eq(uss: 0, pss: 0)
      end
    end

    describe '.file_descriptor_count' do
      it 'returns 0' do
        expect(Dir).to receive(:glob).and_return([])

        expect(described_class.file_descriptor_count).to eq(0)
      end
    end

    describe '.max_open_file_descriptors' do
      it 'returns 0' do
        expect(described_class.max_open_file_descriptors).to eq(0)
      end
    end

    describe '.summary' do
      it 'returns only available fields' do
        summary = described_class.summary

        expect(summary[:version]).to be_a(String)
        expect(summary[:gc_stat].keys).to eq(GC.stat.keys)
        expect(summary[:memory_rss]).to eq(0)
        expect(summary[:memory_uss]).to eq(0)
        expect(summary[:memory_pss]).to eq(0)
        expect(summary[:time_cputime]).to be_a(Float)
        expect(summary[:time_realtime]).to be_a(Float)
        expect(summary[:time_monotonic]).to be_a(Float)
      end
    end
  end

  describe '.cpu_time' do
    it 'returns a Float' do
      expect(described_class.cpu_time).to be_an(Float)
    end
  end

  describe '.real_time' do
    it 'returns a Float' do
      expect(described_class.real_time).to be_an(Float)
    end
  end

  describe '.monotonic_time' do
    it 'returns a Float' do
      expect(described_class.monotonic_time).to be_an(Float)
    end
  end

  describe '.thread_cpu_time' do
    it 'returns cpu_time on supported platform' do
      stub_const("Process::CLOCK_THREAD_CPUTIME_ID", 16)

      expect(Process).to receive(:clock_gettime)
        .with(16, kind_of(Symbol)).and_return(0.111222333)

      expect(described_class.thread_cpu_time).to eq(0.111222333)
    end

    it 'returns nil on unsupported platform' do
      hide_const("Process::CLOCK_THREAD_CPUTIME_ID")

      expect(described_class.thread_cpu_time).to be_nil
    end
  end

  describe '.thread_cpu_duration' do
    let(:start_time) { described_class.thread_cpu_time }

    it 'returns difference between start and current time' do
      stub_const("Process::CLOCK_THREAD_CPUTIME_ID", 16)

      expect(Process).to receive(:clock_gettime)
        .with(16, kind_of(Symbol))
        .and_return(
          0.111222333,
          0.222333833
        )

      expect(described_class.thread_cpu_duration(start_time)).to eq(0.1111115)
    end

    it 'returns nil on unsupported platform' do
      hide_const("Process::CLOCK_THREAD_CPUTIME_ID")

      expect(described_class.thread_cpu_duration(start_time)).to be_nil
    end
  end

  def mock_existing_proc_file(path, content)
    allow(File).to receive(:open).with(path) { |_path, &block| block.call(StringIO.new(content)) }
  end

  def mock_missing_proc_file
    allow(File).to receive(:open).and_raise(Errno::ENOENT)
  end
end
