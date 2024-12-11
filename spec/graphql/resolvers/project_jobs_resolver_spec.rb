# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectJobsResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:irrelevant_project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:irrelevant_pipeline) { create(:ci_pipeline, project: irrelevant_project) }
  let_it_be(:successful_build) { create(:ci_build, :with_build_name, :success, name: 'Build One', pipeline: pipeline) }
  let_it_be(:successful_build_two) { create(:ci_build, :with_build_name, :success, name: 'Build Two', pipeline: pipeline) }
  let_it_be(:failed_build) { create(:ci_build, :failed, :with_build_name, name: 'Build Three', pipeline: pipeline) }
  let_it_be(:pending_build) { create(:ci_build, :pending, :with_build_name, name: 'Build Three', pipeline: pipeline) }
  let_it_be(:irrelevant_build) { create(:ci_build, name: 'Irrelevant Build', pipeline: irrelevant_pipeline) }

  describe '#resolve' do
    let(:args) { {} }

    subject { resolve_jobs(args) }

    context 'with authorized user' do
      let_it_be(:current_user) { create(:user, developer_of: project) }

      context 'with statuses argument' do
        let(:args) { { statuses: [Types::Ci::JobStatusEnum.coerce_isolated_input('SUCCESS')] } }

        it { is_expected.to contain_exactly(successful_build, successful_build_two) }
      end

      context 'with multiple statuses' do
        let(:args) { { statuses: [Types::Ci::JobStatusEnum.coerce_isolated_input('SUCCESS'), Types::Ci::JobStatusEnum.coerce_isolated_input('FAILED')] } }

        it { is_expected.to contain_exactly(successful_build, successful_build_two, failed_build) }
      end

      context 'without statuses argument' do
        it { is_expected.to contain_exactly(successful_build, successful_build_two, failed_build, pending_build) }
      end

      context 'when filtering by source' do
        before do
          stub_feature_flags(populate_and_use_build_source_table: true)
        end

        let_it_be(:successful_build_source) { create(:ci_build_source, build: successful_build, source: 'scan_execution_policy') }
        let_it_be(:pending_build_source) { create(:ci_build_source, build: pending_build, source: 'scan_execution_policy') }
        let(:args) { { sources: %w[scan_execution_policy] } }

        it { is_expected.to contain_exactly(successful_build, pending_build) }

        context 'with multiple sources' do
          let_it_be(:failed_build_source) { create(:ci_build_source, build: failed_build, source: 'trigger') }
          let(:args) { { sources: %w[scan_execution_policy trigger] } }

          it { is_expected.to contain_exactly(successful_build, pending_build, failed_build) }
        end

        context 'when FF is disabled' do
          before do
            stub_feature_flags(populate_and_use_build_source_table: false)
          end

          it 'does not filter by source' do
            is_expected.to contain_exactly(successful_build, successful_build_two, failed_build, pending_build)
          end
        end

        context 'with name filter also present' do
          let(:args) { { name: "Three", sources: %w[scan_execution_policy] } }

          before do
            stub_feature_flags(populate_and_use_build_names_table: true)
          end

          it 'filters only by name' do
            is_expected.to contain_exactly(failed_build, pending_build)
          end
        end

        context 'when given pagination params' do
          let(:cursor) { Base64.strict_encode64({ id: failed_build.id.to_s }.to_json) }
          let(:query) do
            <<~QUERY
            {
              project(fullPath: "#{project.full_path}") {
                jobs(sources: [SCAN_EXECUTION_POLICY], first: 1, after: "#{cursor}") {
                  nodes { id }
                }
              }
            }
            QUERY
          end

          it "returns the paginated build" do
            graphq_response = GitlabSchema.execute(query, context: { current_user: current_user })
            parsed_response = graphql_dig_at(graphq_response, 'data', 'project', 'jobs', 'nodes')
            expect(parsed_response).to match_array([a_graphql_entity_for(pending_build)])
          end
        end
      end

      context 'when filtering by build name' do
        let(:args) { { name: 'Three' } }

        it { is_expected.to contain_exactly(failed_build, pending_build) }

        context 'when FF is disabled' do
          before do
            stub_feature_flags(populate_and_use_build_names_table: false)
          end

          it 'does not filter by name' do
            is_expected.to contain_exactly(successful_build, successful_build_two, failed_build, pending_build)
          end
        end

        context 'when given pagination params' do
          let(:cursor) { Base64.strict_encode64({ id: failed_build.id.to_s }.to_json) }
          let(:args) { { name: 'Three', last: 1, before: cursor } }
          let(:query) do
            job_nodes = 'nodes { id }'
            graphql_query_for(
              :project,
              { full_path: project.full_path },
              query_graphql_field('jobs', args, job_nodes)
            )
          end

          it "returns the paginated build" do
            graphq_response = GitlabSchema.execute(query, context: { current_user: current_user })
            parsed_response = graphql_dig_at(graphq_response, 'data', 'project', 'jobs', 'nodes')
            expect(parsed_response).to match_array([a_graphql_entity_for(pending_build)])
          end

          context 'with bad pagination params' do
            let(:cursor) { "ABCDEFGH" }

            it 'returns a pagination error' do
              graphq_response = GitlabSchema.execute(query, context: { current_user: current_user })
              parsed_response = graphql_dig_at(graphq_response, 'errors', 'message')

              expect(parsed_response).to include('Please provide a valid cursor')
            end
          end
        end
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end
  end

  private

  def resolve_jobs(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
