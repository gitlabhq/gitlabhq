# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai do
  describe '.configure' do
    it 'yields the configuration' do
      expect { |block| described_class.configure(&block) }
        .to yield_with_args(described_class.configuration)
    end
  end

  describe '.configuration' do
    it 'memoizes a single instance' do
      expect(described_class.configuration).to be_a(Banzai::Configuration)
      expect(described_class.configuration).to equal(described_class.configuration)
    end
  end
end
