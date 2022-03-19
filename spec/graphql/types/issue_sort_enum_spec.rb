# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['IssueSort'] do
  specify { expect(described_class.graphql_name).to eq('IssueSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the existing issue sort values' do
    expect(described_class.values.keys).to include(
      *%w[DUE_DATE_ASC DUE_DATE_DESC RELATIVE_POSITION_ASC SEVERITY_ASC SEVERITY_DESC ESCALATION_STATUS_ASC ESCALATION_STATUS_DESC]
    )
  end
end
