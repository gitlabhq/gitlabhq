# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NotesFilterType'], feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('NotesFilterType') }

  it 'exposes all the existing widget type values' do
    expect(described_class.values.transform_values(&:value)).to include(
      "ALL_NOTES" => 0, "ONLY_ACTIVITY" => 2, "ONLY_COMMENTS" => 1
    )
  end
end
