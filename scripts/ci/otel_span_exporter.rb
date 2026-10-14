#!/usr/bin/env ruby
# frozen_string_literal: true

# Uses only the Ruby standard library so jobs on slim Ruby images can run it without `bundle install`.
require 'json'
require 'net/http'
require 'optparse'
require 'securerandom'
require 'timeout'
require 'uri'

# Exports one OpenTelemetry span for a CI script command to GitLab Observability, parented to the CI job span that
# Gitlab::Observability::PipelineToTraces exports. The `otel_span` shell function in scripts/utils.sh runs and times
# the command, then calls this script. Telemetry never changes the job result: export errors are reported as
# warnings and the script always exits successfully.
#
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/632111
class OtelSpanExporter
  ENDPOINT_VARIABLE = 'GLCI_OTEL_ENDPOINT'
  # Same token as Ci::Observability::ExportService::OBSERVABILITY_TOKEN_VARIABLE
  TOKEN_VARIABLE = 'GITLAB_OBSERVABILITY_TOKEN'
  TRACES_PATH = '/v1/traces'
  TRACEPARENT_PATTERN = /\A00-(?<trace_id>[0-9a-f]{32})-(?<parent_span_id>[0-9a-f]{16})-(?<flags>[0-9a-f]{2})\z/
  SPAN_ID_PATTERN = /\A[0-9a-f]{16}\z/
  INVALID_ID_PATTERN = /\A0+\z/
  # Matches the service name Ci::Observability::ExportService passes to the pipeline export.
  SERVICE_NAME = 'gitlab-ci'
  SCOPE_NAME = 'gitlab-ci-script'
  SCOPE_VERSION = '1.0.0'
  SPAN_KIND_INTERNAL = 1
  STATUS_CODE_OK = 1
  STATUS_CODE_ERROR = 2

  # Short enough to export within the runner's grace period after a job is cancelled.
  OPEN_TIMEOUT_S = 1
  READ_TIMEOUT_S = 2
  EXPORT_TIMEOUT_S = 3

  Span = Struct.new(:name, :command, :start_time_ns, :end_time_ns, :exit_code,
    :span_id, :parent_traceparent, :tracestate, keyword_init: true)

  # Parses the command line and exports the span it describes.
  #
  # @param argv [Array<String>] `--name NAME --start-time-ns NS --exit-code CODE [--command COMMAND] [--end-time-ns NS]`
  # @param env [Hash] environment providing the CI/CD variables
  # @param stderr [IO] destination for warnings
  # @return [Integer] always 0, so that telemetry never fails a job
  def self.run(argv, env: ENV, stderr: $stderr, stdout: $stdout)
    exporter = new(env: env, stderr: stderr)
    if argv == ['--prepare-context']
      context = exporter.child_traceparent
      stdout.puts(context) if context
      return 0
    end

    exporter.export(parse(argv))

    0
  rescue OptionParser::ParseError, ArgumentError => e
    exporter.log_warning("invalid arguments: #{e.message}")

    0
  end

  # Parses the span from the command line. The end time defaults to now, so shells without a nanosecond clock don't
  # need to start Ruby to get it.
  #
  # @param argv [Array<String>] command-line arguments
  # @return [Span]
  def self.parse(argv)
    options = { end_time_ns: Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond) }
    OptionParser.new do |opts|
      opts.on('--name NAME') { |value| options[:name] = value }
      opts.on('--command COMMAND') { |value| options[:command] = value }
      opts.on('--start-time-ns NS', Integer) { |value| options[:start_time_ns] = value }
      opts.on('--end-time-ns NS', Integer) { |value| options[:end_time_ns] = value }
      opts.on('--exit-code CODE', Integer) { |value| options[:exit_code] = value }
      opts.on('--span-id ID') { |value| options[:span_id] = value }
      opts.on('--parent-traceparent TRACEPARENT') { |value| options[:parent_traceparent] = value }
      opts.on('--tracestate TRACESTATE') { |value| options[:tracestate] = value }
    end.parse!(argv.dup)

    missing = %i[name start_time_ns exit_code] - options.keys
    raise ArgumentError, "missing #{missing.join(', ')}" unless missing.empty?

    if options[:span_id] && (!SPAN_ID_PATTERN.match?(options[:span_id]) || options[:span_id].match?(INVALID_ID_PATTERN))
      raise ArgumentError, 'invalid span ID'
    end

    Span.new(**options)
  end

  # @param env [Hash] environment providing the CI/CD variables
  # @param stderr [IO] destination for warnings
  def initialize(env: ENV, stderr: $stderr)
    @env = env
    @stderr = stderr
  end

  # Generate a fresh context, preserving a valid parent's trace ID and flags.
  # @return [String, nil] the generated traceparent or nil
  def child_traceparent
    parent = parse_traceparent
    return unless parent

    "00-#{parent[:trace_id]}-#{SecureRandom.hex(8)}-#{parent[:flags]}"
  rescue StandardError => e
    log_warning("span context preparation failed: #{describe_error(e)}")

    nil
  end

  # Sends the span to GitLab Observability. Does nothing when GLCI_OTEL_ENDPOINT is not set.
  #
  # @param span [Span] the span to export
  # @return [void]
  def export(span)
    return if endpoint.nil?

    parent = parse_traceparent(span.parent_traceparent || env['CI_TRACEPARENT'])
    unless parent
      log_warning("#{ENDPOINT_VARIABLE} is set but CI_TRACEPARENT is missing or invalid, skipping span export")
      return
    end

    response = Timeout.timeout(EXPORT_TIMEOUT_S) { post(build_payload(parent, span)) }
    log_warning("span export failed with HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    nil
  rescue StandardError => e
    log_warning("span export failed: #{describe_error(e)}")

    nil
  end

  # @param message [String] warning to print
  # @return [void]
  def log_warning(message)
    stderr.puts("WARNING: otel_span: #{message}")

    nil
  end

  private

  attr_reader :env, :stderr

  def endpoint
    value = env[ENDPOINT_VARIABLE].to_s.strip

    "#{value.chomp('/')}#{TRACES_PATH}" unless value.empty?
  end

  # Mirrors Ci::Observability::ExportService#observability_token.
  def token
    value = env[TOKEN_VARIABLE].to_s.strip
    return if value.empty? || value.match?(/[[:cntrl:]]/)

    value
  end

  def describe_error(error)
    "#{error.class}: #{redact(error.message)}"
  end

  # Error messages can quote the endpoint, its host, or its credentials, so mask them before logging.
  def redact(message)
    raw_endpoint = env[ENDPOINT_VARIABLE].to_s.strip
    secrets = [raw_endpoint, token, *endpoint_parts(raw_endpoint)].compact.reject(&:empty?).uniq

    secrets.sort_by { |secret| -secret.length }.reduce(message.to_s) do |text, secret|
      text.gsub(secret, '[REDACTED]')
    end
  end

  def endpoint_parts(raw_endpoint)
    uri = URI.parse(raw_endpoint)

    [uri.userinfo, uri.user, uri.password, uri.host]
  rescue URI::Error
    []
  end

  def parse_traceparent(value = env['CI_TRACEPARENT'])
    match = TRACEPARENT_PATTERN.match(value.to_s)
    return unless match
    return if match[:trace_id].match?(INVALID_ID_PATTERN) || match[:parent_span_id].match?(INVALID_ID_PATTERN)

    match
  end

  def build_payload(parent, span)
    {
      resourceSpans: [
        {
          resource: { attributes: attributes(resource_attributes) },
          scopeSpans: [
            {
              scope: { name: SCOPE_NAME, version: SCOPE_VERSION },
              spans: [build_span(parent, span)]
            }
          ]
        }
      ]
    }
  end

  def build_span(parent, span)
    {
      traceId: parent[:trace_id],
      spanId: span.span_id || SecureRandom.hex(8),
      parentSpanId: parent[:parent_span_id],
      traceState: span.tracestate || env['CI_TRACESTATE'].to_s,
      name: span.name,
      kind: SPAN_KIND_INTERNAL,
      startTimeUnixNano: span.start_time_ns.to_s,
      endTimeUnixNano: span.end_time_ns.to_s,
      status: span_status(span.exit_code),
      attributes: attributes(span_attributes(span))
    }
  end

  def span_status(exit_code)
    return { code: STATUS_CODE_OK } if exit_code == 0

    { code: STATUS_CODE_ERROR, message: "exit status #{exit_code}" }
  end

  # Matches the Rails exporter service and project identity for shared filters.
  # Omits deployment.environment because Rails.env does not describe the CI runtime.
  def resource_attributes
    {
      'service.name' => SERVICE_NAME,
      'service.version' => env['CI_SERVER_VERSION'],
      'vcs.owner.name' => env['CI_PROJECT_NAMESPACE'],
      'vcs.provider.name' => 'gitlab',
      'vcs.repository.name' => env['CI_PROJECT_TITLE'],
      'gitlab.vcs.repository.id' => env['CI_PROJECT_ID'],
      'vcs.repository.url.full' => env['CI_PROJECT_URL'],
      'gitlab.project.id' => env['CI_PROJECT_ID'],
      'gitlab.project.name' => env['CI_PROJECT_NAME']
    }
  end

  # Records only the command name, because expanded arguments can contain secrets.
  def span_attributes(span)
    {
      'cicd.pipeline.run.id' => env['CI_PIPELINE_ID'],
      'cicd.pipeline.task.name' => env['CI_JOB_NAME'],
      'cicd.pipeline.task.run.id' => env['CI_JOB_ID'],
      'process.executable.name' => span.command && File.basename(span.command),
      'process.exit.code' => span.exit_code
    }
  end

  def attributes(hash)
    hash.filter_map do |key, value|
      next if value.nil? || value == ''

      { key: key, value: value.is_a?(Integer) ? { intValue: value.to_s } : { stringValue: value.to_s } }
    end
  end

  def post(payload)
    uri = URI.parse(endpoint)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{token}" if token
    request.body = JSON.generate(payload)

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: OPEN_TIMEOUT_S,
      read_timeout: READ_TIMEOUT_S,
      write_timeout: READ_TIMEOUT_S
    ) { |http| http.request(request) }
  end
end

exit(OtelSpanExporter.run(ARGV)) if $PROGRAM_NAME == __FILE__
