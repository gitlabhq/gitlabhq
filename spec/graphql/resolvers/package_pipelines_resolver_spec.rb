# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagePipelinesResolver do
  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:generic_package) }
  let_it_be(:pipelines) { create_list(:ci_pipeline, 3, project: package.project) }

  let(:user) { package.project.first_owner }

  it { expect(described_class.extras).to include(:lookahead) }

  describe '#resolve' do
    let(:returned_pipelines) { graphql_dig_at(subject, 'data', 'package', 'pipelines', 'nodes') }
    let(:returned_errors) { graphql_dig_at(subject, 'errors', 'message') }
    let(:pagination_args) { {} }
    let(:query) do
      pipelines_nodes = 'nodes { id }'
      graphql_query_for(
        :package,
        { id: global_id_of(package) },
        query_graphql_field('pipelines', pagination_args, pipelines_nodes)
      )
    end

    subject do
      GitlabSchema.execute(query, context: { current_user: user })
    end

    before do
      pipelines.each do |pipeline|
        create(:package_build_info, package: package, pipeline: pipeline)
      end
    end

    it 'contains the expected pipelines' do
      expect_to_contain_exactly(*pipelines)
    end

    context 'with valid after' do
      let(:pagination_args) { { first: 1, after: encode_cursor(id: pipelines[1].id) } }

      it 'contains the expected pipelines' do
        expect_to_contain_exactly(pipelines[0])
      end
    end

    context 'with valid before' do
      let(:pagination_args) { { last: 1, before: encode_cursor(id: pipelines[1].id) } }

      it 'contains the expected pipelines' do
        expect_to_contain_exactly(pipelines[2])
      end
    end

    context 'with invalid after' do
      let(:pagination_args) { { first: 1, after: 'not_json_string' } }

      it 'generates an argument error' do
        expect(returned_errors).to include('Please provide a valid cursor')
      end
    end

    context 'with invalid after key' do
      let(:pagination_args) { { first: 1, after: encode_cursor(foo: 3) } }

      it 'generates an argument error' do
        expect(returned_errors).to include('Please provide a valid cursor')
      end
    end

    context 'with invalid before' do
      let(:pagination_args) { { last: 1, before: 'not_json_string' } }

      it 'generates an argument error' do
        expect(returned_errors).to include('Please provide a valid cursor')
      end
    end

    context 'with invalid before key' do
      let(:pagination_args) { { last: 1, before: encode_cursor(foo: 3) } }

      it 'generates an argument error' do
        expect(returned_errors).to include('Please provide a valid cursor')
      end
    end

    context 'with unauthorized user' do
      let_it_be(:user) { create(:user) }

      it 'returns nothing' do
        expect(returned_pipelines).to be_nil
      end
    end

    context 'with many packages' do
      let_it_be_with_reload(:other_package) { create(:generic_package, project: package.project) }
      let_it_be(:other_pipelines) { create_list(:ci_pipeline, 3, project: package.project) }

      let(:returned_pipelines) do
        graphql_dig_at(subject, 'data', 'project', 'packages', 'nodes', 'pipelines', 'nodes')
      end

      let(:query) do
        pipelines_query = query_graphql_field('pipelines', pagination_args, 'nodes { id }')
        <<~QUERY
        {
          project(fullPath: "#{package.project.full_path}") {
            packages {
              nodes { #{pipelines_query} }
            }
          }
        }
        QUERY
      end

      before do
        other_pipelines.each do |pipeline|
          create(:package_build_info, package: other_package, pipeline: pipeline)
        end
      end

      it 'contains the expected pipelines' do
        expect_to_contain_exactly(*(pipelines + other_pipelines))
      end

      it 'handles n+1 situations' do
        control = ActiveRecord::QueryRecorder.new do
          GitlabSchema.execute(query, context: { current_user: user })
        end

        create_package_with_pipelines(package.project)

        expectation = expect { GitlabSchema.execute(query, context: { current_user: user }) }

        expectation.not_to exceed_query_limit(control)
      end

      def create_package_with_pipelines(project)
        extra_package = create(:generic_package, project: project)
        create_list(:ci_pipeline, 3, project: project).each do |pipeline|
          create(:package_build_info, package: extra_package, pipeline: pipeline)
        end
      end
    end

    def encode_cursor(json)
      GitlabSchema.cursor_encoder.encode(
        Gitlab::Json.dump(json),
        nonce: true
      )
    end

    def expect_to_contain_exactly(*pipelines)
      entities = pipelines.map { |pipeline| a_graphql_entity_for(pipeline) }
      expect(returned_pipelines).to match_array(entities)
    end
  end
end
