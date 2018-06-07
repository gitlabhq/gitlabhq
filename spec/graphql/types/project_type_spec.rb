require 'spec_helper'

describe GitlabSchema.types['Project'] do
  it { expect(described_class.graphql_name).to eq('Project') }
end
