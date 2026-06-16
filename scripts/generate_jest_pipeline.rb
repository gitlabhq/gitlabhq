#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'erb'

# Generates a per-test-coverage jest child pipeline. Sister to
# generate_rspec_pipeline.rb. Picks parallelism based on the queue size: small
# weekday deltas get a few shards, the weekend bucket sweep gets the full cap.
class GenerateJestPipeline
  SKIP_PIPELINE_YML_FILE = ".gitlab/ci/overrides/skip.yml"
  # The default jest job in the regular pipeline runs at parallel: 11. We cap
  # at the same value so the per-test-coverage runtime profile mirrors the
  # standard suite.
  MAX_PARALLEL_DEFAULT = 11
  # Target test files per shard for sizing. ~500 jest specs/shard at full
  # parallelism keeps each shard well under the 90m timeout even with the
  # instrumented per-test reporter active.
  TARGET_SPECS_PER_SHARD = 500

  def initialize(pipeline_template_path:, jest_files_path: nil, generated_pipeline_path: nil, max_parallel: nil)
    @pipeline_template_path = pipeline_template_path.to_s
    @jest_files_path = jest_files_path.to_s
    @generated_pipeline_path = generated_pipeline_path || "#{pipeline_template_path}.yml"
    @max_parallel = max_parallel&.positive? ? max_parallel : MAX_PARALLEL_DEFAULT

    raise ArgumentError, "pipeline template not found: #{@pipeline_template_path}" \
      unless File.exist?(@pipeline_template_path)
  end

  def generate!
    if jest_files.empty?
      info "Using #{SKIP_PIPELINE_YML_FILE} due to no jest files in queue"
      FileUtils.cp(SKIP_PIPELINE_YML_FILE, generated_pipeline_path)
      return
    end

    info "pipeline_template_path: #{pipeline_template_path}"
    info "generated_pipeline_path: #{generated_pipeline_path}"
    info "Queued #{jest_files.size} jest files, rendering at parallel: #{parallelism}"

    File.open(generated_pipeline_path, 'w') do |handle|
      pipeline_yaml = ERB.new(File.read(pipeline_template_path), trim_mode: '-').result_with_hash(**erb_binding)
      handle.write(pipeline_yaml.squeeze("\n").strip)
    end
  end

  private

  attr_reader :pipeline_template_path, :jest_files_path, :generated_pipeline_path

  def info(text)
    puts "[#{self.class.name}] #{text}"
  end

  def jest_files
    @jest_files ||=
      if File.exist?(jest_files_path)
        File.read(jest_files_path).split("\n").map(&:strip).reject(&:empty?)
      else
        []
      end
  end

  # Linear scale capped at @max_parallel. One shard for tiny weekday queues,
  # full @max_parallel for the weekend bucket sweep.
  def parallelism
    [[jest_files.size.fdiv(TARGET_SPECS_PER_SHARD).ceil, 1].max, @max_parallel].min
  end

  def erb_binding
    {
      parallelism: parallelism,
      repo_from_artifacts: ENV['CI_FETCH_REPO_GIT_STRATEGY'] == 'none'
    }
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}

  OptionParser.new do |opts|
    opts.on("-f", "--jest-files-path PATH", String, "File containing jest spec paths, one per line") do |value|
      options[:jest_files_path] = value
    end

    opts.on("-t", "--pipeline-template-path PATH", String, "ERB template for the child pipeline") do |value|
      options[:pipeline_template_path] = value
    end

    opts.on("-o", "--generated-pipeline-path PATH", String, "Where to write the rendered child pipeline") do |value|
      options[:generated_pipeline_path] = value
    end

    opts.on("-n", "--max-parallel COUNT", Integer,
      "Maximum parallel value (default: #{GenerateJestPipeline::MAX_PARALLEL_DEFAULT})") do |value|
      options[:max_parallel] = value
    end

    opts.on("-h", "--help", "Print this help") do
      puts opts
      exit
    end
  end.parse!

  GenerateJestPipeline.new(**options).generate!
end
