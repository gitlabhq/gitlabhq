# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SastCiConfiguration'] do
  let(:fields) { %i[global pipeline analyzers] }

  it { expect(described_class.graphql_name).to eq('SastCiConfiguration') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
