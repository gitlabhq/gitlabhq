# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DesignVersionEvent'] do
  it { expect(described_class.graphql_name).to eq('DesignVersionEvent') }

  it 'exposes the correct event states' do
    expect(described_class.values.keys).to include(*%w[CREATION MODIFICATION DELETION NONE])
  end
end
