# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestNewState'] do
  it 'has the appropriate values' do
    expect(described_class.values).to contain_exactly(
      ['OPEN', have_attributes(value: 'reopen')],
      ['CLOSED', have_attributes(value: 'close')]
    )
  end
end
