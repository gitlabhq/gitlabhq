# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SastCiConfigurationAnalyzersEntity'] do
  let(:fields) { %i[name label enabled description variables] }

  it { expect(described_class.graphql_name).to eq('SastCiConfigurationAnalyzersEntity') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
