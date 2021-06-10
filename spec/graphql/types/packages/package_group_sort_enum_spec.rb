# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageGroupSort'] do
  it 'exposes all package group sort values' do
    expect(described_class.values.keys).to contain_exactly(*%w[CREATED_DESC CREATED_ASC NAME_DESC NAME_ASC PROJECT_PATH_DESC PROJECT_PATH_ASC VERSION_DESC VERSION_ASC TYPE_DESC TYPE_ASC])
  end
end
