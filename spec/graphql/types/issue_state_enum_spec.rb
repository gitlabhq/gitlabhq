# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['IssueState'] do
  it { expect(described_class.graphql_name).to eq('IssueState') }

  it_behaves_like 'issuable state'
end
