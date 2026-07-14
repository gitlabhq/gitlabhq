# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Granular token authorization in GraphQL', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:other_group) { create(:group, :private) }
  let_it_be(:user) { create(:user, developer_of: [group, other_group]) }

  describe 'a root query field with a boundary_argument directive on its resolver' do
    let(:resolver) do
      Class.new(Resolvers::BaseResolver) do
        authorize_granular_token permissions: :read_wiki, boundary_argument: :full_path, boundary_type: :group

        type GraphQL::Types::String, null: true

        argument :full_path, GraphQL::Types::ID, required: true

        def resolve(full_path:)
          "rules for #{full_path}"
        end
      end
    end

    let(:query_type) do
      field_resolver = resolver

      Class.new(Types::BaseObject) do
        graphql_name 'Query'

        field :tool_rules, resolver: field_resolver
      end
    end

    let(:query_string) { %({ toolRules(fullPath: "#{group.full_path}") }) }

    def execute_as(token)
      schema = empty_schema
      schema.query(query_type)

      schema.execute(query_string, context: { current_user: user, access_token: token }).to_h
    end

    context 'with a legacy personal access token' do
      let(:token) { create(:personal_access_token, user: user) }

      it 'resolves the field' do
        expect(execute_as(token).dig('data', 'toolRules')).to eq("rules for #{group.full_path}")
      end
    end

    context 'with a granular token holding the required permission on the boundary' do
      let(:token) do
        create(:granular_pat, user: user, boundary: Authz::Boundary.for(group), permissions: [:read_wiki])
      end

      it 'resolves the field' do
        expect(execute_as(token).dig('data', 'toolRules')).to eq("rules for #{group.full_path}")
      end
    end

    context 'with a granular token missing the required permission' do
      let(:token) do
        create(:granular_pat, user: user, boundary: Authz::Boundary.for(group), permissions: [:create_work_item])
      end

      it 'nulls the field' do
        expect(execute_as(token).dig('data', 'toolRules')).to be_nil
      end
    end

    context 'with a granular token scoped to a different boundary' do
      let(:token) do
        create(:granular_pat, user: user, boundary: Authz::Boundary.for(other_group), permissions: [:read_wiki])
      end

      it 'nulls the field' do
        expect(execute_as(token).dig('data', 'toolRules')).to be_nil
      end
    end
  end
end
