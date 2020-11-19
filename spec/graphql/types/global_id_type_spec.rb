# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::GlobalIDType do
  let_it_be(:project) { create(:project) }
  let(:gid) { project.to_global_id }
  let(:foreign_gid) { GlobalID.new(::URI::GID.build(app: 'otherapp', model_name: 'Project', model_id: project.id, params: nil)) }

  it 'is has the correct name' do
    expect(described_class.to_graphql.name).to eq('GlobalID')
  end

  describe '.coerce_result' do
    it 'can coerce results' do
      expect(described_class.coerce_isolated_result(gid)).to eq(gid.to_s)
    end

    it 'rejects integer IDs' do
      expect { described_class.coerce_isolated_result(project.id) }
        .to raise_error(ArgumentError)
    end

    it 'rejects strings' do
      expect { described_class.coerce_isolated_result('not a GID') }
        .to raise_error(ArgumentError)
    end
  end

  describe '.coerce_input' do
    it 'can coerce valid input' do
      coerced = described_class.coerce_isolated_input(gid.to_s)

      expect(coerced).to eq(gid)
    end

    it 'handles all valid application GIDs' do
      expect { described_class.coerce_isolated_input(build_stubbed(:user).to_global_id.to_s) }
        .not_to raise_error
    end

    it 'rejects invalid input' do
      expect { described_class.coerce_isolated_input('not valid') }
        .to raise_error(GraphQL::CoercionError)
    end

    it 'rejects nil' do
      expect(described_class.coerce_isolated_input(nil)).to be_nil
    end

    it 'rejects gids from different apps' do
      expect { described_class.coerce_isolated_input(foreign_gid) }
        .to raise_error(GraphQL::CoercionError)
    end
  end

  describe 'a parameterized type' do
    let(:type) { ::Types::GlobalIDType[::Project] }

    it 'is has the correct name' do
      expect(type.to_graphql.name).to eq('ProjectID')
    end

    context 'the GID is appropriate' do
      it 'can coerce results' do
        expect(type.coerce_isolated_result(gid)).to eq(gid.to_s)
      end

      it 'can coerce IDs to a GlobalIDType' do
        expect(type.coerce_isolated_result(project.id)).to eq(gid.to_s)
      end

      it 'can coerce valid input' do
        expect(type.coerce_isolated_input(gid.to_s)).to eq(gid)
      end
    end

    context 'the GID is not for an appropriate type' do
      let(:gid) { build_stubbed(:user).to_global_id }

      it 'raises errors when coercing results' do
        expect { type.coerce_isolated_result(gid) }.to raise_error(GraphQL::CoercionError)
      end

      it 'will not coerce invalid input, even if its a valid GID' do
        expect { type.coerce_isolated_input(gid.to_s) }
          .to raise_error(GraphQL::CoercionError)
      end
    end
  end

  describe 'a parameterized type with a namespace' do
    let(:type) { ::Types::GlobalIDType[::Ci::Build] }

    it 'is has a valid GraphQL identifier for a name' do
      expect(type.to_graphql.name).to eq('CiBuildID')
    end
  end

  describe 'compatibility' do
    def query(doc, vars)
      GraphQL::Query.new(schema, document: doc, context: {}, variables: vars)
    end

    def run_query(gql_query, vars)
      query(GraphQL.parse(gql_query), vars).result
    end

    all_types = [::GraphQL::ID_TYPE, ::Types::GlobalIDType, ::Types::GlobalIDType[::Project]]

    shared_examples 'a working query' do
      # Simplified schema to test compatibility
      let!(:schema) do
        # capture values so they can be closed over
        arg_type = argument_type
        res_type = result_type

        project = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Project'
          field :name, String, null: false
          field :id, res_type, null: false, resolver_method: :global_id

          def global_id
            object.to_global_id
          end
        end

        Class.new(GraphQL::Schema) do
          query(Class.new(GraphQL::Schema::Object) do
            graphql_name 'Query'

            field :project_by_id, project, null: true do
              argument :id, arg_type, required: true
            end

            # This is needed so that all types are always registered as input types
            field :echo, String, null: true do
              argument :id, ::GraphQL::ID_TYPE, required: false
              argument :gid, ::Types::GlobalIDType, required: false
              argument :pid, ::Types::GlobalIDType[::Project], required: false
            end

            def project_by_id(id:)
              gid = ::Types::GlobalIDType[::Project].coerce_isolated_input(id)
              gid.model_class.find(gid.model_id)
            end

            def echo(id: nil, gid: nil, pid: nil)
              "id: #{id}, gid: #{gid}, pid: #{pid}"
            end
          end)
        end
      end

      it 'works' do
        res = run_query(document, 'projectId' => project.to_global_id.to_s)

        expect(res['errors']).to be_blank
        expect(res.dig('data', 'project', 'name')).to eq(project.name)
        expect(res.dig('data', 'project', 'id')).to eq(project.to_global_id.to_s)
      end
    end

    context 'when the client declares the argument as ID the actual argument can be any type' do
      let(:document) do
        <<-GRAPHQL
        query($projectId: ID!){
          project: projectById(id: $projectId) {
            name, id
          }
        }
        GRAPHQL
      end

      where(:result_type, :argument_type) do
        all_types.flat_map { |arg_type| all_types.zip([arg_type].cycle) }
      end

      with_them do
        it_behaves_like 'a working query'
      end
    end

    context 'when the client passes the argument as GlobalID' do
      let(:document) do
        <<-GRAPHQL
        query($projectId: GlobalID!) {
          project: projectById(id: $projectId) {
            name, id
          }
        }
        GRAPHQL
      end

      let(:argument_type) { ::Types::GlobalIDType }

      where(:result_type) { all_types }

      with_them do
        it_behaves_like 'a working query'
      end
    end

    context 'when the client passes the argument as ProjectID' do
      let(:document) do
        <<-GRAPHQL
        query($projectId: ProjectID!) {
          project: projectById(id: $projectId) {
            name, id
          }
        }
        GRAPHQL
      end

      let(:argument_type) { ::Types::GlobalIDType[::Project] }

      where(:result_type) { all_types }

      with_them do
        it_behaves_like 'a working query'
      end
    end
  end
end
