# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SastCiConfigurationOptionsEntity'] do
  let(:fields) { %i[label value] }

  it { expect(described_class.graphql_name).to eq('SastCiConfigurationOptionsEntity') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
