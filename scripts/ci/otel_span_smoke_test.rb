#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

Dir.mktmpdir('otel-span-smoke') do |directory|
  exporter = File.join(directory, 'exporter.rb')
  log = File.join(directory, 'export.log')
  # Parses the arguments with the real exporter, so the check fails when the shell passes invalid span arguments.
  File.write(exporter, <<~RUBY)
    require 'json'
    require #{File.expand_path('otel_span_exporter', __dir__).inspect}
    if ARGV == ['--prepare-context']
      OtelSpanExporter.run(ARGV)
    else
      File.open(ENV.fetch('SPAN_LOG'), 'a') { |f| f.puts(JSON.generate(OtelSpanExporter.parse(ARGV).to_h)) }
    end
  RUBY

  env = {
    'GLCI_OTEL_ENDPOINT' => 'http://otel.invalid',
    'GLCI_OTEL_SPAN_EXPORTER' => exporter,
    'SPAN_LOG' => log,
    'CI_TRACEPARENT' => '00-00000000000000000000000000000001-1234567890abcdef-01'
  }
  utils = File.expand_path('../utils.sh', __dir__)
  [0, 7].each do |exit_code|
    FileUtils.rm_f(log)
    output, error, status = Open3.capture3(env, 'busybox', 'sh', '-c', <<~SH)
      set -eo pipefail
      . '#{utils}'
      task() { export RESULT="$1"; echo "$RESULT"; return #{exit_code}; }
      otel_span smoke -- task 'two words'
      echo "after:$RESULT"
    SH
    expected = exit_code == 0 ? "two words\nafter:two words\n" : "two words\n"
    raise "Command behavior changed: #{error}" unless status.exitstatus == exit_code && output == expected

    spans = File.exist?(log) ? File.readlines(log).map { |line| JSON.parse(line) } : []
    valid = spans.size == 1 &&
      spans.first.values_at('name', 'command', 'exit_code') == ['smoke', 'task', exit_code] &&
      spans.first['parent_traceparent'] == env['CI_TRACEPARENT']
    raise "Expected one valid span, got #{spans.inspect}: #{error}" unless valid
  end
end

puts 'BusyBox otel_span smoke checks passed'
