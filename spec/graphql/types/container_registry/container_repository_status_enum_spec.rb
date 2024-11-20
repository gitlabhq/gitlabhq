# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryStatus'], feature_category: :container_registry do
  it 'exposes all statuses' do
    expect(described_class.values.keys).to match_array(ContainerRepository.statuses.keys.map(&:upcase))
  end
end
