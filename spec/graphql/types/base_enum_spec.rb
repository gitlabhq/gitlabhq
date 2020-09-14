# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseEnum do
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

  include_examples 'Gitlab-style deprecations' do
    def subject(args = {})
      enum = Class.new(described_class) do
        graphql_name 'TestEnum'

        value 'TEST_VALUE', **args
      end

      enum.to_graphql.values['TEST_VALUE']
    end
  end
end
