# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::CustomIntrospection::DynamicFields, feature_category: :api do
  include GraphqlHelpers

  describe '__typename field' do
    it 'has complexity of 0.2' do
      field = described_class.fields['__typename']

      expect(field.complexity).to eq(0.2)
    end

    it 'adds correct query complexity value' do
      query_with_typename = <<~GQL
        query {
          currentUser {
            id
            __typename
          }
        }
      GQL

      query_without_typename = <<~GQL
        query {
          currentUser {
            id
          }
        }
      GQL

      complexity_with = calculate_query_complexity(query_with_typename)
      complexity_without = calculate_query_complexity(query_without_typename)

      expect(complexity_with).to eq(complexity_without + 0.2)
    end
  end
end
