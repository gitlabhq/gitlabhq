# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Diff'], feature_category: :code_review_workflow do
  include RepoHelpers
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('Diff') }

  it 'contains attributes related to diff' do
    expect(described_class).to have_graphql_fields(
      :a_mode, :b_mode, :deleted_file, :diff, :new_file, :new_path, :old_path, :renamed_file
    )
  end

  describe '#diff' do
    subject { resolve_field(:diff, diff, object_type: described_class) }

    let(:merge_request_diff) { create(:merge_request).merge_request_diff }
    let(:diff) { merge_request_diff.diffs.diffs.first }

    it 'returns the diff of the passed commit' do
      is_expected.to eq(diff.diff)
    end
  end
end
