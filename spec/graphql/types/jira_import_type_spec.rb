# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['JiraImport'] do
  specify { expect(described_class.graphql_name).to eq('JiraImport') }

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:jira_project_key, :createdAt, :scheduled_at, :scheduled_by)
  end
end
