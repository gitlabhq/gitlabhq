# frozen_string_literal: true

require 'spec_helper'
require 'yaml'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::ChildPipeline do
  subject(:pipeline) { YAML.safe_load(described_class.new(names, **options).to_yaml) }

  let(:names) { %w[alpha beta] }
  let(:options) { {} }

  it 'includes the static template rather than inlining job configuration' do
    expect(pipeline['include']).to contain_exactly({ 'local' => described_class::TEMPLATE_PATH })
  end

  it 'emits one distill job per principle' do
    expect(pipeline.slice('distill:alpha', 'distill:beta')).to eq(
      'distill:alpha' => {
        'extends' => described_class::DISTILL_BASE_JOB,
        'resource_group' => "#{described_class::RESOURCE_GROUP_PREFIX}-0",
        'variables' => { 'AI_PRINCIPLE_NAME' => 'alpha' }
      },
      'distill:beta' => {
        'extends' => described_class::DISTILL_BASE_JOB,
        'resource_group' => "#{described_class::RESOURCE_GROUP_PREFIX}-1",
        'variables' => { 'AI_PRINCIPLE_NAME' => 'beta' }
      }
    )
  end

  # The collect job needs the list it was SUPPOSED to receive: an absent artifact only means "this job never ran" when
  # measured against an expected set.
  # Recomputing it in the collect job would risk the two stages disagreeing, since collect is never given the
  # --force / --only flags the generator scanned with.
  it 'passes the expected principle list to the collect job' do
    expect(pipeline[described_class::COLLECT_JOB]['variables'])
      .to eq({ described_class::EXPECTED_VARIABLE => 'alpha,beta' })
  end

  describe 'concurrency slots' do
    let(:names) { %w[a b c d e f] }
    let(:options) { { concurrency: 2 } }

    # A resource group is a semaphore of exactly one, so N named groups give a cap of N.
    # This is what holds concurrency at the previous in-process cap and keeps the split from adding any load to the
    # shared DAP scheduler.
    it 'assigns slots round-robin so at most `concurrency` jobs run at once' do
      slots = names.map { |name| pipeline["distill:#{name}"]['resource_group'] }

      expect(slots).to eq(
        %w[
          ai-principles-distill-slot-0 ai-principles-distill-slot-1
          ai-principles-distill-slot-0 ai-principles-distill-slot-1
          ai-principles-distill-slot-0 ai-principles-distill-slot-1
        ]
      )
    end

    it 'uses no more distinct slots than the concurrency cap' do
      slots = names.map { |name| pipeline["distill:#{name}"]['resource_group'] }

      expect(slots.uniq.size).to eq(2)
    end
  end

  # The split must not raise concurrency above what the in-process pool already allowed, or it would add load to the
  # shared DAP scheduler rather than just redistributing it.
  context 'when no concurrency cap is given' do
    let(:names) { (1..10).map { |i| "p#{i}" } }

    it 'defaults to the in-process cap' do
      slots = names.map { |name| pipeline["distill:#{name}"]['resource_group'] }

      expect(slots.uniq.size).to eq(Gitlab::PrinciplesDistiller::Sync::MAX_CONCURRENT_DISTILLATIONS)
    end
  end

  # A child pipeline needs at least one job to be valid, and the collect job comes from the included template.
  # This keeps the "everything is up to date" path identical to the ordinary one (collect runs, finds nothing, reports a
  # clean run) rather than a special case in the parent.
  context 'when no principles are affected' do
    let(:names) { [] }

    # Asserted as a whole: the point is that the pipeline contains the template include and the collect job and
    # nothing else, which a per-key assertion would not catch.
    it 'still yields a valid pipeline with an empty expected list' do
      expect(pipeline).to eq(
        'include' => [{ 'local' => described_class::TEMPLATE_PATH }],
        described_class::COLLECT_JOB => {
          'variables' => { described_class::EXPECTED_VARIABLE => '' }
        }
      )
    end
  end
end
