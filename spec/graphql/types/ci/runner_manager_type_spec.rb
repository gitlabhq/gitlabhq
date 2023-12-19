# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunnerManager'], feature_category: :fleet_visibility do
  specify { expect(described_class.graphql_name).to eq('CiRunnerManager') }

  specify { expect(described_class).to require_graphql_authorizations(:read_runner_manager) }

  it 'contains attributes related to a runner manager' do
    expected_fields = %w[
      architecture_name contacted_at created_at executor_name id ip_address job_execution_status platform_name revision
      runner status system_id version
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
