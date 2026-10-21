# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::MergeSourceType, feature_category: :code_review_workflow do
  let(:fields) { %i[merge_request commit_sha] }

  specify { expect(described_class.graphql_name).to eq('MergeRequestMergeSource') }
  specify { expect(described_class).to have_graphql_fields(fields) }
end
