# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::CiConfiguration::Sast::AnalyzersEntityInputType do
  it { expect(described_class.graphql_name).to eq('SastCiConfigurationAnalyzersEntityInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[enabled name variables]) }
end
