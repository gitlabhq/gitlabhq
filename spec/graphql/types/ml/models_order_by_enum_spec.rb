# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModelsOrderBy'], feature_category: :mlops do
  specify { expect(described_class.graphql_name).to eq('MlModelsOrderBy') }

  it 'exposes all the existing order by types' do
    expect(described_class.values.keys).to match_array(%w[CREATED_AT ID UPDATED_AT NAME])
  end
end
