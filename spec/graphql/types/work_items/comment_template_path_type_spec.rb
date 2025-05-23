# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::CommentTemplatePathType, feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('CommentTemplatePathType') }

  it 'has the expected fields' do
    expected_fields = %i[
      href
      text
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
