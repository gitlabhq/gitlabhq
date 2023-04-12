# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTrace'], feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:job) { create(:ci_build) }

  it 'has the correct fields' do
    expected_fields = [:html_summary]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  it 'shows the correct trace contents' do
    job.trace.set('BUILD TRACE')

    expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
      expect(trace).to receive(:html).with(last_lines: 10).and_call_original
    end

    resolved_field = resolve_field(:html_summary, job.trace)

    expect(resolved_field).to eq("<span>BUILD TRACE</span>")
  end
end
