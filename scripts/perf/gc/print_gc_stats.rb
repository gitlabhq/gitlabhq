# frozen_string_literal: true

# Promotes survivors from eden to old gen and runs a compaction.
#
# aka "Nakayoshi GC"
#
# https://github.com/puma/puma/blob/de632261ac45d7dd85230c83f6af6dd720f1cbd9/lib/puma/util.rb#L26-L35
def nakayoshi_gc
  4.times { GC.start(full_mark: false) }
  GC.compact
end

# GC::Profiler is used elsewhere in the code base, so we provide a way for it
# to be used exclusively by this script, or otherwise results will be tainted.
module GC::Profiler
  class << self
    attr_accessor :use_exclusive

    %i[enable disable clear].each do |method|
      alias_method "#{method}_orig", method.to_s

      define_method(method) do
        if use_exclusive
          warn "GC::Profiler: ignoring call to #{method}"
          return
        end

        send("#{method}_orig") # rubocop: disable GitlabSecurity/PublicSend
      end
    end
  end
end

GC::Profiler.enable
GC::Profiler.use_exclusive = true

require 'benchmark'

RAILS_ROOT = ENV['RAILS_ROOT']

tms = Benchmark.measure do
  require RAILS_ROOT + 'config/boot'
  require RAILS_ROOT + 'config/environment'
end

GC::Profiler.use_exclusive = false

nakayoshi_gc

gc_stats = GC.stat
warn gc_stats.inspect

gc_total_time = GC::Profiler.total_time

GC::Profiler.report($stderr)
GC::Profiler.disable

gc_stat_keys = ENV['GC_STAT_KEYS'].to_s.split(',').map(&:to_sym)

values = []
values << ENV['SETTING_CSV']
values += gc_stat_keys.map { |k| gc_stats[k] }
values << ::Gitlab::Metrics::System.memory_usage_rss[:total]
values << gc_total_time
values << (tms.utime + tms.cutime)
values << (tms.stime + tms.cstime)
values << tms.real

puts values.join(',')
