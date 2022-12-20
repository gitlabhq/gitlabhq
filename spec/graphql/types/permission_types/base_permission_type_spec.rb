# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::BasePermissionType do
  let(:permitable) { double('permittable') }
  let(:current_user) { build(:user) }
  let(:context) { { current_user: current_user } }

  subject(:test_type) do
    Class.new(described_class) do
      graphql_name 'TestClass'

      permission_field :do_stuff
      ability_field(:read_issue)
      abilities :admin_issue

      define_method :do_stuff do
        true
      end
    end
  end

  describe '.permission_field' do
    it 'adds a field for the required permission' do
      expect(test_type).to have_graphql_field(:do_stuff)
    end
  end

  describe '.ability_field' do
    it 'adds a field for the required permission' do
      expect(test_type).to have_graphql_field(:read_issue)
    end

    it 'does not add a resolver block if another resolving param is passed' do
      expected_keywords = {
        name: :resolve_using_hash,
        hash_key: :the_key,
        type: GraphQL::Types::Boolean,
        description: "custom description",
        null: false
      }
      expect(test_type).to receive(:field).with(expected_keywords)

      test_type.ability_field :resolve_using_hash, hash_key: :the_key, description: "custom description"
    end
  end

  describe '.abilities' do
    it 'adds a field for the passed permissions' do
      expect(test_type).to have_graphql_field(:admin_issue)
    end
  end

  describe 'extensions' do
    subject(:test_type) do
      Class.new(described_class) do
        graphql_name 'TestClass'

        permission_field :read_entity_a do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end

        ability_field(:read_entity_b) do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end
      end
    end

    it 'has the extension' do
      expect(test_type.fields['readEntityA'].extensions).to include(a_kind_of(::Gitlab::Graphql::Limit::FieldCallCount))
      expect(test_type.fields['readEntityB'].extensions).to include(a_kind_of(::Gitlab::Graphql::Limit::FieldCallCount))
    end
  end
end
