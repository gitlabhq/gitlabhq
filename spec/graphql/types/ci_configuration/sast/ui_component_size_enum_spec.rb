# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::CiConfiguration::Sast::UiComponentSizeEnum do
  specify { expect(described_class.graphql_name).to eq('SastUiComponentSize') }

  it 'exposes all sizes of ui components' do
    expect(described_class.values.keys).to include(*%w[SMALL MEDIUM LARGE])
  end
end
