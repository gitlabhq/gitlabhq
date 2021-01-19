# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::CiConfiguration::Sast::InputType do
  it { expect(described_class.graphql_name).to eq('SastCiConfigurationInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[global pipeline analyzers]) }
end
