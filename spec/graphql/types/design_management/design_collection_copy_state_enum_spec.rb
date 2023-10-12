# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DesignCollectionCopyState'] do
  it { expect(described_class.graphql_name).to eq('DesignCollectionCopyState') }

  it 'exposes the correct event states' do
    expect(described_class.values.keys).to match_array(%w[READY IN_PROGRESS ERROR])
  end
end
