# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseEdge, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:test_schema) do
    project_edge_type = Class.new(described_class) do
      field :proof_of_admin_rights, String, null: true, authorize: :admin_project

      def proof_of_admin_rights
        'ok'
      end
    end

    project_type = Class.new(::Types::BaseObject) do
      graphql_name 'Project'
      authorize :read_project
      edge_type_class project_edge_type

      field :name, String, null: false
    end

    Class.new(GraphQL::Schema) do
      lazy_resolve ::Gitlab::Graphql::Lazy, :force
      use ::Gitlab::Graphql::Pagination::Connections

      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'
        field :projects, project_type.connection_type, null: false

        def projects
          context[:projects]
        end
      end)
    end
  end

  def document
    GraphQL.parse(<<~GQL)
    query {
      projects {
        edges {
          proofOfAdminRights
          node { name }
        }
      }
    }
    GQL
  end

  it 'supports field authorization on edge fields' do
    user = create(:user)
    private_project = create(:project, :private)
    member_project = create(:project, :private)
    maintainer_project = create(:project, :private)
    public_project = create(:project, :public)

    member_project.add_developer(user)
    maintainer_project.add_maintainer(user)
    projects = [private_project, member_project, maintainer_project, public_project]

    data = { current_user: user, projects: projects }
    query = GraphQL::Query.new(test_schema, document: document, context: data)
    result = query.result.to_h

    expect(graphql_dig_at(result, 'data', 'projects', 'edges', 'node', 'name'))
      .to contain_exactly(member_project.name, maintainer_project.name, public_project.name)

    expect(graphql_dig_at(result, 'data', 'projects', 'edges', 'proofOfAdminRights'))
      .to contain_exactly(nil, 'ok', nil)
  end
end
