# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['JiraUser'] do
  specify { expect(described_class.graphql_name).to eq('JiraUser') }

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(
      :jira_account_id, :jira_display_name, :jira_email, :gitlab_id, :gitlab_username, :gitlab_name
    )
  end
end
