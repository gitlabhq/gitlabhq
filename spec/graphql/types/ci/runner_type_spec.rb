# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunner'], feature_category: :runner do
  specify { expect(described_class.graphql_name).to eq('CiRunner') }

  specify { expect(described_class).to require_graphql_authorizations(:read_runner) }

  it 'contains attributes related to a runner' do
    expected_fields = %w[
      id description created_by created_at contacted_at managers maximum_timeout access_level active paused status
      short_sha locked run_untagged runner_type tag_list
      project_count job_count admin_url edit_admin_url register_admin_url user_permissions
      maintenance_note maintenance_note_html groups projects jobs token_expires_at
      owner_project job_execution_status ephemeral_authentication_token ephemeral_register_url creation_method
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'URLs to admin area', :enable_admin_mode do
    let_it_be(:runner) { create(:ci_runner, :instance) }

    let(:query) do
      %(
          query{
            runners {
              nodes {
                adminUrl
                editAdminUrl
              }
            }
          }
        )
    end

    subject(:response) { GitlabSchema.execute(query, context: { current_user: current_user }) }

    context 'when current user is an admin' do
      let_it_be(:current_user) { create(:admin) }

      it 'is not nil' do
        runner = response.dig('data', 'runners', 'nodes', 0)

        expect(runner['adminUrl']).not_to be_nil
        expect(runner['editAdminUrl']).not_to be_nil
      end
    end
  end
end
