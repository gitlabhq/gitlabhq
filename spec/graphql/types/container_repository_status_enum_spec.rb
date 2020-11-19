# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryStatus'] do
  it 'exposes all statuses' do
    expect(described_class.values.keys).to contain_exactly(*ContainerRepository.statuses.keys.map(&:upcase))
  end
end
