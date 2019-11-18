# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['IssueSort'] do
  it { expect(described_class.graphql_name).to eq('IssueSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the existing issue sort values' do
    expect(described_class.values.keys).to include(*%w[DUE_DATE_ASC DUE_DATE_DESC RELATIVE_POSITION_ASC])
  end
end
