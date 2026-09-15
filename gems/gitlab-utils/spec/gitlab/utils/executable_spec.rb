# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::Executable do
  let(:service_class) do
    Class.new do
      include Gitlab::Utils::Executable

      attr_reader :positional, :keyword, :block

      def initialize(*positional, **keyword, &block)
        @positional = positional
        @keyword = keyword
        @block = block
      end

      def execute
        { positional: positional, keyword: keyword, block: block&.call }
      end
    end
  end

  describe '.execute' do
    it 'forwards positional arguments, keyword arguments and the block to the service instance' do
      result = service_class.execute(:foo, :bar, baz: 1) { :from_block }

      expect(result).to eq(positional: [:foo, :bar], keyword: { baz: 1 }, block: :from_block)
    end

    context 'when the superclass defines its own singleton execute method' do
      let(:superclass) do
        Class.new do
          def self.execute(...)
            :from_superclass
          end

          def execute
            :from_instance
          end
        end
      end

      let(:subclass) do
        Class.new(superclass) do
          include Gitlab::Utils::Executable
        end
      end

      it 'takes precedence over the inherited method' do
        expect(subclass.execute).to eq(:from_instance)
      end

      it 'leaves the superclass untouched' do
        expect(superclass.execute).to eq(:from_superclass)
      end
    end
  end
end
