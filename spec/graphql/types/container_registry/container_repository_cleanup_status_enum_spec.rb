# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryCleanupStatus'], feature_category: :container_registry do
  it 'exposes all statuses' do
    expected_keys = ContainerRepository.expiration_policy_cleanup_statuses
                                       .keys
                                       .map { |k| k.gsub('cleanup_', '') }
                                       .map(&:upcase)
    expect(described_class.values.keys).to match_array(expected_keys)
  end
end
