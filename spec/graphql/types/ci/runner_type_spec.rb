# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunner'], feature_category: :runner do
  specify { expect(described_class.graphql_name).to eq('CiRunner') }

  specify { expect(described_class).to require_graphql_authorizations(:read_runner) }

  it 'contains attributes related to a runner' do
    expected_fields = %w[
      id description created_by created_at contacted_at managers maximum_timeout access_level active paused status
      version short_sha revision locked run_untagged ip_address runner_type tag_list
      project_count job_count admin_url edit_admin_url register_admin_url user_permissions executor_name
      architecture_name platform_name maintenance_note maintenance_note_html groups projects jobs token_expires_at
      owner_project job_execution_status ephemeral_authentication_token ephemeral_register_url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
