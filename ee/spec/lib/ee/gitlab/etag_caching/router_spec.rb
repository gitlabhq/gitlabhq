require 'spec_helper'

describe Gitlab::EtagCaching::Router do
  it 'matches epic notes endpoint' do
    result = described_class.match(
      '/groups/my-group/and-subgroup/-/epics/1/notes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'epic_notes'
  end

  it 'does not match invalid epic notes endpoint' do
    result = described_class.match(
      '/groups/my-group/-/and-subgroup/-/epics/1/notes'
    )

    expect(result).to be_blank
  end
end
