# frozen_string_literal: true

require 'spec_helper'

describe Types::BaseEnum do
  describe '#enum' do
    let(:enum) do
      Class.new(described_class) do
        value 'TEST', value: 3
        value 'other'
        value 'NORMAL'
      end
    end

    it 'adds all enum values to #enum' do
      expect(enum.enum.keys).to contain_exactly('test', 'other', 'normal')
      expect(enum.enum.values).to contain_exactly(3, 'other', 'NORMAL')
    end

    it 'is a HashWithIndefferentAccess' do
      expect(enum.enum).to be_a(HashWithIndifferentAccess)
    end
  end
end
