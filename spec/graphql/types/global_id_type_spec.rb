# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::GlobalIDType do
  include GraphqlHelpers
  include GlobalIDDeprecationHelpers

  let_it_be(:project) { create(:project) }

  let(:gid) { project.to_global_id }

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
        .to raise_error(GraphQL::CoercionError, /not a valid Global ID/)
    end

    it 'rejects nil' do
      expect(described_class.coerce_isolated_input(nil)).to be_nil
    end

    it 'rejects GIDs from different apps' do
      invalid_gid = GlobalID.new(::URI::GID.build(app: 'otherapp', model_name: 'Project', model_id: project.id, params: nil))

      expect { described_class.coerce_isolated_input(invalid_gid) }
        .to raise_error(GraphQL::CoercionError, /is not a Gitlab Global ID/)
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
        expect { type.coerce_isolated_result(gid) }
          .to raise_error(GraphQL::CoercionError, /Expected a Project ID/)
      end

      it 'will not coerce invalid input, even if its a valid GID' do
        expect { type.coerce_isolated_input(gid.to_s) }
          .to raise_error(GraphQL::CoercionError, /does not represent an instance of Project/)
      end
    end

    it 'handles GIDs for invalid resource names gracefully' do
      invalid_gid = GlobalID.new(::URI::GID.build(app: GlobalID.app, model_name: 'invalid', model_id: 1, params: nil))

      expect { type.coerce_isolated_input(invalid_gid) }
        .to raise_error(GraphQL::CoercionError, /does not represent an instance of Project/)
    end

    context 'with a deprecation' do
      around do |example|
        # Unset all previously memoized GlobalIDTypes to allow us to define one
        # that will use the constants stubbed in the `before` block.
        previous_id_types = Types::GlobalIDType.instance_variable_get(:@id_types)
        Types::GlobalIDType.instance_variable_set(:@id_types, {})

        example.run
      ensure
        Types::GlobalIDType.instance_variable_set(:@id_types, previous_id_types)
      end

      before do
        deprecation = Gitlab::GlobalId::Deprecations::Deprecation.new(old_model_name: 'OldIssue', new_model_name: 'Issue', milestone: '10.0')

        stub_global_id_deprecations(deprecation)
      end

      let_it_be(:issue) { create(:issue) }

      let!(:type) { ::Types::GlobalIDType[::Issue] }
      let(:deprecated_gid) { Gitlab::GlobalId.build(model_name: 'OldIssue', id: issue.id) }
      let(:deprecating_gid) { Gitlab::GlobalId.build(model_name: 'Issue', id: issue.id) }

      it 'appends the description with a deprecation notice for the old Global ID' do
        expect(type.to_graphql.description).to include('The older format `"gid://gitlab/OldIssue/1"` was deprecated in 10.0')
      end

      describe 'coercing input against the type (parsing the Global ID string when supplied as an argument)' do
        subject(:result) { type.coerce_isolated_input(gid.to_s) }

        context 'when passed the deprecated Global ID' do
          let(:gid) { deprecated_gid }

          it 'changes the model_name to the new model name' do
            expect(result.model_name).to eq('Issue')
          end

          it 'changes the model_class to the new model class' do
            expect(result.model_class).to eq(Issue)
          end

          it 'can find the correct resource' do
            expect(result.find).to eq(issue)
          end

          it 'can find the correct resource loaded through GitlabSchema' do
            expect(force(GitlabSchema.object_from_id(result, expected_class: Issue))).to eq(issue)
          end
        end

        context 'when passed the Global ID that is deprecating another' do
          let(:gid) { deprecating_gid }

          it 'works as normal' do
            expect(result).to have_attributes(
              model_class: Issue,
              model_name: 'Issue',
              find: issue,
              to_s: gid.to_s
            )
          end
        end
      end

      describe 'coercing the result against the type (producing the Global ID string when used in a field)' do
        context 'when passed the deprecated Global ID' do
          let(:gid) { deprecated_gid }

          it 'works, but does not result in matching the new Global ID', :aggregate_failures do
            # Note, this would normally never happen in real life as the object being parsed
            # by the field would not produce the GlobalID of the deprecated model. This test
            # proves that it is technically possible for the deprecated GlobalID to be
            # considered parsable for the type, as opposed to raising a `GraphQL::CoercionError`.
            expect(type.coerce_isolated_result(gid)).not_to eq(issue.to_global_id.to_s)
            expect(type.coerce_isolated_result(gid)).to eq(gid.to_s)
          end
        end

        context 'when passed the Global ID that is deprecating another' do
          let(:gid) { deprecating_gid }

          it 'works as normal' do
            expect(type.coerce_isolated_result(gid)).to eq(issue.to_global_id.to_s)
          end
        end
      end

      describe 'executing against the schema' do
        let(:query_result) do
          context = { current_user: issue.project.owner }
          variables = { 'id' => gid }

          run_with_clean_state(query, context: context, variables: variables).to_h
        end

        shared_examples 'a query that works with old and new GIDs' do
          let(:query) do
            <<-GQL
            query($id: #{argument_name}!) {
              issue(id: $id) {
                id
              }
            }
            GQL
          end

          subject { query_result.dig('data', 'issue', 'id') }

          context 'when the argument value is the new GID' do
            let(:gid) { Gitlab::GlobalId.build(model_name: 'Issue', id: issue.id) }

            it { is_expected.to be_present }
          end

          context 'when the argument value is the old GID' do
            let(:gid) { Gitlab::GlobalId.build(model_name: 'OldIssue', id: issue.id) }

            it { is_expected.to be_present }
          end
        end

        context 'when the query signature includes the old type name' do
          let(:argument_name) { 'OldIssueID' }

          it_behaves_like 'a query that works with old and new GIDs'
        end

        context 'when the query signature includes the new type name' do
          let(:argument_name) { 'IssueID' }

          it_behaves_like 'a query that works with old and new GIDs'
        end
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

    all_types = [::GraphQL::Types::ID, ::Types::GlobalIDType, ::Types::GlobalIDType[::Project]]

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
              argument :id, ::GraphQL::Types::ID, required: false
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

  describe '.model_name_to_graphql_name' do
    it 'returns a graphql name for the given model name' do
      expect(described_class.model_name_to_graphql_name('DesignManagement::Design')).to eq('DesignManagementDesignID')
    end
  end
end
