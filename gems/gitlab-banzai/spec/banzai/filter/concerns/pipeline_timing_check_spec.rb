# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::Concerns::PipelineTimingCheck do
  let(:described_class) { PipelineTest }

  before do
    stub_const('Banzai::Filter::Concerns::PipelineTimingCheck::MAX_PIPELINE_SECONDS', 1)
    stub_const('PipelineTest', Class.new(HTML::Pipeline::Filter))
    PipelineTest.class_eval { include Banzai::Filter::Concerns::PipelineTimingCheck }
  end

  def filter_with_timing(pipeline_timing)
    described_class.new('text').tap do |filter|
      allow(filter).to receive(:result).and_return({ pipeline_timing: pipeline_timing })
    end
  end

  it 'returns true if MAX_PIPELINE_SECONDS exceeded' do
    expect(filter_with_timing(1.1).exceeded_pipeline_max?).to be(true)
  end

  it 'returns false if MAX_PIPELINE_SECONDS not exceeded' do
    expect(filter_with_timing(0.9).exceeded_pipeline_max?).to be(false)
  end

  it 'returns false when the pipeline has not been timed' do
    expect(described_class.new('text').exceeded_pipeline_max?).to be_falsey
  end

  context 'when the `timeout_disabled` port is on' do
    before do
      Banzai.configure { |config| config.timeout_disabled = true }
    end

    it 'ignores MAX_PIPELINE_SECONDS' do
      expect(filter_with_timing(1.1).exceeded_pipeline_max?).to be(false)
    end
  end

  context 'when the context disables the timeout' do
    it 'ignores MAX_PIPELINE_SECONDS' do
      filter = described_class.new('text', { disable_banzai_timeout: true })
      allow(filter).to receive(:result).and_return({ pipeline_timing: 1.1 })

      expect(filter.exceeded_pipeline_max?).to be(false)
    end
  end
end
