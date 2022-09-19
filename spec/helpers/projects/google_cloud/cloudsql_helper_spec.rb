# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::CloudsqlHelper do
  describe '#TIERS' do
    it 'is an array' do
      expect(described_class::TIERS).to be_an_instance_of(Array)
    end
  end

  describe '#VERSIONS' do
    it 'returns versions for :postgres' do
      expect(described_class::VERSIONS[:postgres]).to be_an_instance_of(Array)
    end

    it 'returns versions for :mysql' do
      expect(described_class::VERSIONS[:mysql]).to be_an_instance_of(Array)
    end

    it 'returns versions for :sqlserver' do
      expect(described_class::VERSIONS[:sqlserver]).to be_an_instance_of(Array)
    end
  end
end
