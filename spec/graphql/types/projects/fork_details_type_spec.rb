# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ForkDetails'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('ForkDetails') }

  it 'has specific fields' do
    fields = %i[
      ahead
      behind
      isSyncing
      hasConflicts
    ]

    expect(described_class).to have_graphql_fields(*fields)
  end
end
