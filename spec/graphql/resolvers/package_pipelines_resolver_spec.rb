# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagePipelinesResolver do
  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:package) }
  let_it_be(:pipelines) { create_list(:ci_pipeline, 3, project: package.project) }

  let(:user) { package.project.first_owner }

  describe '#resolve' do
    let(:returned_pipeline_ids) { graphql_dig_at(subject, 'data', 'package', 'pipelines', 'nodes', 'id') }
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

    shared_examples 'returning the expected pipelines' do
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
          expect(returned_pipeline_ids).to eq(nil)
        end
      end

      context 'with many packages' do
        let_it_be_with_reload(:other_package) { create(:package, project: package.project) }
        let_it_be(:other_pipelines) { create_list(:ci_pipeline, 3, project: package.project) }

        let(:returned_pipeline_ids) do
          graphql_dig_at(subject, 'data', 'project', 'packages', 'nodes', 'pipelines', 'nodes', 'id')
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

          if Feature.enabled?(:packages_graphql_pipelines_resolver)
            expectation.not_to exceed_query_limit(control)
          else
            expectation.to exceed_query_limit(control)
          end
        end

        def create_package_with_pipelines(project)
          extra_package = create(:package, project: project)
          create_list(:ci_pipeline, 3, project: project).each do |pipeline|
            create(:package_build_info, package: extra_package, pipeline: pipeline)
          end
        end
      end
    end

    context 'with packages_graphql_pipelines_resolver enabled' do
      before do
        expect_detect_mode([:new_finder])
      end

      it_behaves_like 'returning the expected pipelines'
    end

    context 'with packages_graphql_pipelines_resolver disabled' do
      before do
        stub_feature_flags(packages_graphql_pipelines_resolver: false)
        expect_detect_mode([:old_finder, :object_field])
      end

      it_behaves_like 'returning the expected pipelines'
    end

    def encode_cursor(json)
      GitlabSchema.cursor_encoder.encode(
        Gitlab::Json.dump(json),
        nonce: true
      )
    end

    def expect_to_contain_exactly(*pipelines)
      ids = pipelines.map { |pipeline| global_id_of(pipeline) }
      expect(returned_pipeline_ids).to contain_exactly(*ids)
    end

    def expect_detect_mode(modes)
      allow_next_instance_of(described_class) do |resolver|
        detect_mode_method = resolver.method(:detect_mode)
        allow(resolver).to receive(:detect_mode) do
          result = detect_mode_method.call

          expect(modes).to include(result)
          result
        end
      end
    end
  end

  describe '.field options' do
    let(:field) do
      field_options = described_class.field_options.merge(
        owner: resolver_parent,
        name: 'dummy_field'
      )
      ::Types::BaseField.new(**field_options)
    end

    it 'sets them properly' do
      expect(field).not_to be_connection
      expect(field.extras).to match_array([:lookahead])
    end
  end
end
