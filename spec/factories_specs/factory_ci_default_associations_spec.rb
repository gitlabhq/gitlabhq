# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Factory default associations for CI records', feature_category: :tooling do
  row = FactoryDefaults::Row

  it_behaves_like 'factory default associations', [
    *%i[
      ci_build ci_stage ci_job_artifact ci_workload generic_commit_status ci_running_build managed_resource
    ].map do |factory|
      row.new(factory: factory, skip: :project, passed: { project: :project }, strategies: %i[create])
    end,
    row.new(
      factory: :ci_pending_build, skip: :project, passed: { project: :project },
      expected: ->(project, _) { { project: project, build: an_object_having_attributes(project: project) } },
      strategies: %i[create]
    )
  ]
end
