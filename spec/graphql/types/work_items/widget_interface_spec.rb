# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetInterface do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[type]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    it 'knows the correct type for objects' do
      expect(
        described_class.resolve_type(WorkItems::Widgets::Description.new(build(:work_item)), {})
      ).to eq(Types::WorkItems::Widgets::DescriptionType)
    end

    it 'raises an error for an unknown type' do
      project = build(:project)

      expect_graphql_error_to_be_created("Unknown GraphQL type for widget #{project}") do
        described_class.resolve_type(project, {})
      end
    end
  end
end
