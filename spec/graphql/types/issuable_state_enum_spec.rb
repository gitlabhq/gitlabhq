# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['IssuableState'] do
  specify { expect(described_class.graphql_name).to eq('IssuableState') }

  it_behaves_like 'issuable state'
end
