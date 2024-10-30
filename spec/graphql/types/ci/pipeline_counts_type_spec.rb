# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineCounts'], feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }
  let_it_be(:success_pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:ref_pipeline) { create(:ci_pipeline, project: project, ref: 'awesome-feature') }
  let_it_be(:sha_pipeline) { create(:ci_pipeline, :running, project: project, sha: 'deadbeef') }
  let_it_be(:on_demand_dast_scan) { create(:ci_pipeline, :success, project: project, source: 'ondemand_dast_scan') }

  before_all do
    project.add_developer(current_user)
  end

  specify { expect(described_class.graphql_name).to eq('PipelineCounts') }

  it 'has the expected fields' do
    expected_fields = %w[
      all
      finished
      pending
      running
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  shared_examples 'pipeline counts query' do |expected_counts:, args: ""|
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelineCounts#{args} {
              all
              finished
              pending
              running
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    it 'returns pipeline counts' do
      actual_counts = subject.dig('data', 'project', 'pipelineCounts')

      expect(actual_counts).to eq(expected_counts)
    end
  end

  it_behaves_like "pipeline counts query", args: "", expected_counts: {
    "all" => 6,
    "finished" => 3,
    "pending" => 2,
    "running" => 1
  }

  it_behaves_like "pipeline counts query", args: '(ref: "awesome-feature")', expected_counts: {
    "all" => 1,
    "finished" => 0,
    "pending" => 1,
    "running" => 0
  }

  it_behaves_like "pipeline counts query", args: '(sha: "deadbeef")', expected_counts: {
    "all" => 1,
    "finished" => 0,
    "pending" => 0,
    "running" => 1
  }

  it_behaves_like "pipeline counts query", args: '(source: "ondemand_dast_scan")', expected_counts: {
    "all" => 1,
    "finished" => 1,
    "pending" => 0,
    "running" => 0
  }
end
