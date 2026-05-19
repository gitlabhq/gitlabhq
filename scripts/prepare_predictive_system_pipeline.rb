#!/usr/bin/env ruby

# frozen_string_literal: true

require 'fileutils'

# Prepares inputs for the full system test child pipeline and the matching-tests filter files.
#
# Responsibilities:
#   1. When Duo ran (GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH exists, even if empty):
#      - Duo completed and its answer is trusted. An empty file means Duo is confident
#        that 0 system tests are needed; a non-empty file lists the predicted specs.
#      - If specs were predicted: appends them to the FOSS/EE matching-tests filter files,
#        keeping any detect-tests-selected system tests (union of both).
#      - If 0 specs predicted: Duo has nothing to add; detect-tests-selected system tests
#        remain in the filter files.
#      - Writes a no-op for the full system test child pipeline in both cases.
#   2. When Duo is not confident or fails in a tier-2 pipeline (file absent):
#      - Strips system tests from the FOSS/EE matching-tests filter files so the predictive
#        pipeline does not duplicate them.
#      - Copies the full system test child pipeline template (full suite runs via child pipeline).
#   3. Otherwise (tier-1, tier-3, spec-only, or Duo not configured for this project):
#      - Writes a no-op for the full system test child pipeline.
class PreparePredictiveSystemPipeline
  SKIP_PIPELINE_YML_FILE = ".gitlab/ci/overrides/skip.yml"
  SYSTEM_SPEC_PATTERN = %r{spec/features/}

  def initialize(
    duo_system_tests_path:,
    foss_matching_tests_path:,
    ee_matching_tests_path:,
    system_full_pipeline_yml:,
    system_full_pipeline_template:,
    merge_request_labels: ""
  )
    @duo_system_tests_path = duo_system_tests_path
    @foss_matching_tests_path = foss_matching_tests_path
    @ee_matching_tests_path = ee_matching_tests_path
    @system_full_pipeline_yml = system_full_pipeline_yml
    @system_full_pipeline_template = system_full_pipeline_template
    @merge_request_labels = merge_request_labels
  end

  def run!
    if duo_ran?
      if duo_has_predictions?
        info "Duo confident: merging #{count_files(duo_system_tests_path)} predicted specs into matching tests files..."
        merge_duo_predictions!
        info "  FOSS test count: #{count_files(foss_matching_tests_path)}"
        info "  EE test count: #{count_files(ee_matching_tests_path)}"
      else
        info "Duo has no predictions; detect-tests-selected system tests remain in filter files."
      end

      write_skip_pipeline!
    elsif tier_2? && !spec_only?
      info "Duo is not confident or failed on tier-2: generating full system test child pipeline."
      info "Stripping system tests from predictive matching tests (covered by full system test pipeline)."
      strip_system_tests!
      render_full_pipeline!
    else
      info "Using no-op for full system test pipeline (tier-1, spec-only, or Duo not applicable)."
      write_skip_pipeline!
    end
  end

  private

  attr_reader :duo_system_tests_path, :foss_matching_tests_path, :ee_matching_tests_path,
    :system_full_pipeline_yml, :system_full_pipeline_template, :merge_request_labels

  def info(text)
    $stdout.puts "[#{self.class.name}] #{text}" # rubocop:disable Gitlab/DirectStdio -- CLI script, no logger available
  end

  # Duo ran if the output file exists, even if empty.
  # An empty file means Duo is confident 0 system tests are needed.
  # A missing file means Duo bailed out (job failed, timed out, or was skipped).
  def duo_ran?
    File.exist?(duo_system_tests_path.to_s)
  end

  def duo_has_predictions?
    duo_ran? && File.size?(duo_system_tests_path.to_s)
  end

  def tier_2?
    merge_request_labels.include?('pipeline::tier-2')
  end

  def spec_only?
    merge_request_labels.include?('pipeline:spec-only')
  end

  def backup_matching_tests!
    [foss_matching_tests_path, ee_matching_tests_path].each do |path|
      next unless File.exist?(path.to_s)

      FileUtils.cp(path, "#{path}.orig")
    end
  end

  def merge_duo_predictions!
    backup_matching_tests!
    FileUtils.mkdir_p(File.dirname(foss_matching_tests_path))
    FileUtils.mkdir_p(File.dirname(ee_matching_tests_path))

    foss_specs = []
    ee_specs = []

    File.foreach(duo_system_tests_path) do |spec|
      spec = spec.chomp.strip
      next if spec.empty?

      if spec.start_with?("ee/spec/") && spec.match?(SYSTEM_SPEC_PATTERN)
        ee_specs << spec
      elsif spec.start_with?("spec/") && spec.match?(SYSTEM_SPEC_PATTERN)
        foss_specs << spec
      end
    end

    append_unique_specs(foss_matching_tests_path, foss_specs)
    append_unique_specs(ee_matching_tests_path, ee_specs)
  end

  def append_unique_specs(path, new_specs)
    return if new_specs.empty?

    existing = File.exist?(path.to_s) ? File.read(path).split : []
    unique_new = new_specs - existing
    return if unique_new.empty?

    File.open(path, 'a') { |f| f.write(" #{unique_new.join(' ')}") }
  end

  def strip_system_tests!
    backup_matching_tests!
    [foss_matching_tests_path, ee_matching_tests_path].each do |path|
      next unless File.exist?(path.to_s)

      files = File.read(path).split.reject { |f| f.match?(SYSTEM_SPEC_PATTERN) }
      File.write(path, files.join(' '))
    end
  end

  def render_full_pipeline!
    FileUtils.cp(system_full_pipeline_template, system_full_pipeline_yml)
  end

  def write_skip_pipeline!
    FileUtils.cp(SKIP_PIPELINE_YML_FILE, system_full_pipeline_yml)
  end

  def count_files(path)
    File.exist?(path.to_s) ? File.read(path).split.size : 0
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    PreparePredictiveSystemPipeline.new(
      duo_system_tests_path: ENV.fetch('GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH', ''),
      foss_matching_tests_path: ENV.fetch('GLCI_PREDICTIVE_RSPEC_MATCHING_TESTS_FOSS_PATH', ''),
      ee_matching_tests_path: ENV.fetch('GLCI_PREDICTIVE_RSPEC_MATCHING_TESTS_EE_PATH', ''),
      system_full_pipeline_yml: ENV.fetch('GLCI_PREDICTIVE_RSPEC_SYSTEM_FULL_PIPELINE_YML', ''),
      system_full_pipeline_template: File.join(
        ENV.fetch('CI_PROJECT_DIR', Dir.pwd),
        '.gitlab/ci/rails/rspec-predictive-system-full.gitlab-ci.yml'
      ),
      merge_request_labels: ENV.fetch('CI_MERGE_REQUEST_LABELS', '')
    ).run!
  rescue StandardError => e
    puts "[prepare_predictive_system_pipeline] ERROR: #{e.message}"
    exit 1
  end
end
