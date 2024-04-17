# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ExtensionsMarketplaceOptInStatusEnum, feature_category: :web_ide do
  specify { expect(described_class.graphql_name).to eq('ExtensionsMarketplaceOptInStatus') }

  it 'exposes all the existing extensions_marketplace_opt_in_status values' do
    expect(described_class.values.keys).to contain_exactly('UNSET', 'ENABLED', 'DISABLED')
  end
end
