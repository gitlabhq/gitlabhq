# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Blame::BlameType, feature_category: :source_code_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('Blame') }

  specify do
    expect(described_class).to have_graphql_fields(
      :first_line,
      :groups
    ).at_least
  end
end
