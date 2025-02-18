# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::DescriptionTemplateType, feature_category: :portfolio_management do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[content name category projectId]

    expected_fields.each do |field|
      expect(described_class).to have_graphql_field(field)
    end
  end
end
