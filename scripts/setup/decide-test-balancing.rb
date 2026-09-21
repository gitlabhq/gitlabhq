#!/usr/bin/env ruby
# frozen_string_literal: true

# Decides whether dynamic RSpec test balancing is enabled and prints the result
# as a dotenv line (`retrieve-tests-metadata` publishes it; prepare-as-if-foss-env
# exports it for the child trigger).
#
# If GLCI_USE_TEST_BALANCING is already set, the decision was made upstream (the
# as-if-foss child inherits the parent's value via the trigger job) and is
# honored as-is, so the child follows the parent.
#
# Otherwise balancing is enabled by default. The `pipeline:skip-test-balancing`
# MR label opts out entirely (an escape hatch when balancing misbehaves on an MR).
class DecideTestBalancing
  SKIP_LABEL = 'pipeline:skip-test-balancing'

  def enabled?
    return inherited_value if inherited?

    !label_skipped?
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

  def labels
    @labels ||= ENV['CI_MERGE_REQUEST_LABELS'].to_s.split(',')
  end
end

puts DecideTestBalancing.new.to_dotenv if $PROGRAM_NAME == __FILE__
