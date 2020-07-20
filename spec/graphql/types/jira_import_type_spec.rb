# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['JiraImport'] do
  specify { expect(described_class.graphql_name).to eq('JiraImport') }

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(
      :jira_project_key, :created_at, :scheduled_at, :scheduled_by,
      :failed_to_import_count, :imported_issues_count, :total_issue_count
    )
  end
end
