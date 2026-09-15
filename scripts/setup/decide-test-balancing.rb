#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'

# Decides whether dynamic RSpec test balancing is enabled and prints the result
# as a dotenv line (`retrieve-tests-metadata` publishes it; prepare-as-if-foss-env
# exports it for the child trigger).
#
# The decision must be consistent across every rspec job in a pipeline. Rolling
# the dice inside the parallel runner would let each lane flip its own coin, so it
# is decided once here. The random sample is seeded on CI_PIPELINE_ID, so any job
# in the same pipeline that computes it gets the same answer.
#
# If GLCI_USE_TEST_BALANCING is already set, the decision was made upstream (the
# as-if-foss child inherits the parent's value via the trigger job) and is
# honored as-is rather than re-rolled, so the child follows the parent.
#
# Otherwise: the `pipeline:skip-test-balancing` MR label opts out entirely (an
# escape hatch when balancing misbehaves on an MR); the `pipeline:use-test-balancing`
# label forces it on; otherwise a random 30% of pipelines enable it.
class DecideTestBalancing
  ROLLOUT_RATIO = 0.3
  FORCE_LABEL = 'pipeline:use-test-balancing'
  SKIP_LABEL = 'pipeline:skip-test-balancing'

  def enabled?
    return inherited_value if inherited?
    return false if label_skipped?

    label_forced? || sampled?
  end

  def to_dotenv
    "GLCI_USE_TEST_BALANCING=#{enabled?}"
  end

  private

  def inherited?
    !ENV['GLCI_USE_TEST_BALANCING'].to_s.empty?
  end

  def inherited_value
    ENV['GLCI_USE_TEST_BALANCING'] == 'true'
  end

  def label_skipped?
    labels.include?(SKIP_LABEL)
  end

  def label_forced?
    labels.include?(FORCE_LABEL)
  end

  # Deterministic per-pipeline sample so any job that computes the decision in the
  # same pipeline agrees (the parent's retrieve-tests-metadata and
  # prepare-as-if-foss-env both roll, and must match). Seed on CI_PIPELINE_ID;
  # falls back to a random roll when it is absent (e.g. local runs).
  def sampled?
    pipeline_id = ENV['CI_PIPELINE_ID'].to_s
    return rand < ROLLOUT_RATIO if pipeline_id.empty?

    Random.new(Digest::SHA256.hexdigest(pipeline_id).to_i(16)).rand < ROLLOUT_RATIO
  end

  def labels
    @labels ||= ENV['CI_MERGE_REQUEST_LABELS'].to_s.split(',')
  end
end

puts DecideTestBalancing.new.to_dotenv if $PROGRAM_NAME == __FILE__
