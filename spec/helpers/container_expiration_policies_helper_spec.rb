# frozen_string_literal: true

require 'spec_helper'

describe ContainerExpirationPoliciesHelper do
  describe '#keep_n_options' do
    it 'returns keep_n options formatted for dropdown usage' do
      expected_result = [
        { key: 1, label: '1 tag per image name' },
        { key: 5, label: '5 tags per image name' },
        { key: 10, label: '10 tags per image name' },
        { key: 25, label: '25 tags per image name' },
        { key: 50, label: '50 tags per image name' },
        { key: 100, label: '100 tags per image name' }
      ]

      expect(helper.keep_n_options).to eq(expected_result)
    end
  end

  describe '#cadence_options' do
    it 'returns cadence options formatted for dropdown usage' do
      expected_result = [
        { key: '1d', label: 'Every day' },
        { key: '7d', label: 'Every week' },
        { key: '14d', label: 'Every two weeks' },
        { key: '1month', label: 'Every month' },
        { key: '3month', label: 'Every three months' }
      ]

      expect(helper.cadence_options).to eq(expected_result)
    end
  end

  describe '#older_than_options' do
    it 'returns older_than options formatted for dropdown usage' do
      expected_result = [
        { key: '7d', label: '7 days until tags are automatically removed' },
        { key: '14d', label: '14 days until tags are automatically removed' },
        { key: '30d', label: '30 days until tags are automatically removed' },
        { key: '90d', label: '90 days until tags are automatically removed' }
      ]

      expect(helper.older_than_options).to eq(expected_result)
    end
  end
end
