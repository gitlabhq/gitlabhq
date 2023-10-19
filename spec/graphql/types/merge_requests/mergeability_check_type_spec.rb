# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::MergeabilityCheckType, feature_category: :code_review_workflow do
  let(:fields) { %i[identifier status] }

  specify { expect(described_class.graphql_name).to eq('MergeRequestMergeabilityCheck') }
  specify { expect(described_class).to have_graphql_fields(fields) }
end
