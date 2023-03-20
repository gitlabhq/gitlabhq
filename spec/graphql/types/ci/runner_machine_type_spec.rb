# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunnerMachine'], feature_category: :runner_fleet do
  specify { expect(described_class.graphql_name).to eq('CiRunnerMachine') }

  specify { expect(described_class).to require_graphql_authorizations(:read_runner_machine) }

  it 'contains attributes related to a runner machine' do
    expected_fields = %w[
      architecture_name contacted_at created_at executor_name id ip_address platform_name revision
      runner status system_id version
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
