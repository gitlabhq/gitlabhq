# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageSort'] do
  it 'exposes all package sort values' do
    expect(described_class.values.keys).to contain_exactly(*%w[CREATED_DESC CREATED_ASC NAME_DESC NAME_ASC VERSION_DESC VERSION_ASC TYPE_DESC TYPE_ASC])
  end
end
