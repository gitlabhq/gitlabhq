# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType do
  specify { expect(described_class.graphql_name).to eq('Pipeline') }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }

  it 'contains attributes related to a pipeline' do
    expected_fields = %w[
      id iid sha before_sha status detailed_status config_source duration
      coverage created_at updated_at started_at finished_at committed_at
      stages user retryable cancelable jobs source_job downstream
      upstream path project active user_permissions
    ]

    if Gitlab.ee?
      expected_fields << 'security_report_summary'
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
