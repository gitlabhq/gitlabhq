# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineAnalyticsJobStatus'], feature_category: :fleet_visibility do
  it 'exposes all job status types' do
    expect(described_class.values.keys).to contain_exactly(*%w[ANY SUCCESS FAILED OTHER])
  end
end
