# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItemSort'], feature_category: :team_planning, unless: Gitlab.ee? do
  specify { expect(described_class.graphql_name).to eq('WorkItemSort') }

  it 'exposes all the existing work item sort values' do
    expect(described_class.values.keys).to match_array(
      %w[
        CLOSED_AT_ASC CLOSED_AT_DESC CREATED_ASC CREATED_DESC DUE_DATE_ASC DUE_DATE_DESC ESCALATION_STATUS_ASC
        ESCALATION_STATUS_DESC LABEL_PRIORITY_ASC LABEL_PRIORITY_DESC MILESTONE_DUE_ASC MILESTONE_DUE_DESC
        POPULARITY_ASC POPULARITY_DESC PRIORITY_ASC PRIORITY_DESC RELATIVE_POSITION_ASC SEVERITY_ASC SEVERITY_DESC
        START_DATE_ASC START_DATE_DESC TITLE_ASC TITLE_DESC UPDATED_ASC UPDATED_DESC
        created_asc created_desc updated_asc updated_desc
      ]
    )
  end
end
