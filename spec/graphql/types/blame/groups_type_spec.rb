# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Blame::GroupsType, feature_category: :source_code_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('Groups') }

  specify do
    expect(described_class).to have_graphql_fields(
      :commit,
      :commit_data,
      :lineno,
      :lines,
      :span
    ).at_least
  end
end
