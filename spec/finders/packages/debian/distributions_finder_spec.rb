# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::DistributionsFinder do
  it_behaves_like 'Debian Distributions Finder', :debian_project_distribution, true
  it_behaves_like 'Debian Distributions Finder', :debian_group_distribution, false

  context 'with nil container' do
    let(:service) { described_class.new(nil) }

    subject { service.execute.to_a }

    it 'raises error' do
      expect { subject }.to raise_error ArgumentError, "Unexpected container type of 'NilClass'"
    end
  end

  context 'with unexpected container type' do
    let(:service) { described_class.new(:invalid) }

    subject { service.execute.to_a }

    it 'raises error' do
      expect { subject }.to raise_error ArgumentError, "Unexpected container type of 'Symbol'"
    end
  end
end
