# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineMergeRequestEventType'], feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('PipelineMergeRequestEventType') }

  it 'has specific values' do
    expect(described_class.values).to match a_hash_including(
      'MERGED_RESULT' => have_attributes(value: :merged_result),
      'DETACHED' => have_attributes(value: :detached)
    )
  end
end
