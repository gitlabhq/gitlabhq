# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Branch'] do
  it { expect(described_class.graphql_name).to eq('Branch') }

  it { expect(described_class).to have_graphql_fields(:name, :commit) }
end
