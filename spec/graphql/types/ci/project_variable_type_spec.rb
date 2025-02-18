# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiProjectVariable'], feature_category: :ci_variables do
  specify { expect(described_class.interfaces).to contain_exactly(Types::Ci::VariableInterface) }

  specify do
    expect(described_class)
    .to have_graphql_fields(
      :environment_scope,
      :masked,
      :protected,
      :description,
      :hidden).at_least

    expect(described_class.graphql_name).to eq('CiProjectVariable')
  end
end
