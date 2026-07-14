# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Configs::Options, :aggregate_failures, feature_category: :settings do
  let(:config) { { foo: { bar: 'baz' } } }

  subject(:options) { described_class.build(config) }

  shared_examples 'do not mutate' do |method|
    context 'when no callback is installed (default)' do
      it 'raises an exception to avoid changing the internal keys' do
        exception = "Warning: Do not mutate Gitlab::Configs::Options objects: `#{method}`"

        expect { options.send(method) }.to raise_error(exception)
      end
    end

    context 'when a callback is installed' do
      let(:received_messages) { [] }

      before do
        Gitlab::Configs.on_mutation_warning = ->(message, extra) { received_messages << { message: message, extra: extra } }
      end

      after do
        Gitlab::Configs.on_mutation_warning = nil
      end

      it 'invokes the callback with the message, method, and caller, and returns the converted hash' do
        result = options.send(method)

        expect(result).to be_truthy
        expect(received_messages.length).to eq(1)
        expect(received_messages.first[:message]).to eq(
          "Warning: Do not mutate Gitlab::Configs::Options objects: `#{method}`"
        )
        expect(received_messages.first[:extra]).to include(method: method)
        expect(received_messages.first[:extra][:caller]).to be_an(Array).and(be_present)
      end
    end
  end

  describe '.build' do
    context 'when argument is a hash' do
      it 'creates a new Gitlab::Configs::Options instance' do
        options = described_class.build(config)

        expect(options).to be_a described_class
        expect(options.foo).to be_a described_class
        expect(options.foo.bar).to eq 'baz'
      end
    end
  end

  describe '#default' do
    it 'returns the option value' do
      expect(options.default).to be_nil

      options['default'] = 'The default value'

      expect(options.default).to eq('The default value')
    end
  end

  describe '#[]' do
    it 'accesses the configuration key as string' do
      expect(options['foo']).to be_a described_class
      expect(options['foo']['bar']).to eq 'baz'

      expect(options['inexistent']).to be_nil
    end

    it 'accesses the configuration key as symbol' do
      expect(options[:foo]).to be_a described_class
      expect(options[:foo][:bar]).to eq 'baz'

      expect(options[:inexistent]).to be_nil
    end
  end

  describe '#[]=' do
    it 'changes the configuration key as string' do
      options['foo']['bar'] = 'anothervalue'

      expect(options['foo']['bar']).to eq 'anothervalue'
    end

    it 'changes the configuration key as symbol' do
      options[:foo][:bar] = 'anothervalue'

      expect(options[:foo][:bar]).to eq 'anothervalue'
    end

    context 'when key does not exist' do
      it 'creates a new configuration by string key' do
        options['inexistent'] = 'value'

        expect(options['inexistent']).to eq 'value'
      end

      it 'creates a new configuration by string key' do
        options[:inexistent] = 'value'

        expect(options[:inexistent]).to eq 'value'
      end
    end
  end

  describe '#key?' do
    it 'checks if a string key exists' do
      expect(options.key?('foo')).to be true
      expect(options.key?('inexistent')).to be false
    end

    it 'checks if a symbol key exists' do
      expect(options.key?(:foo)).to be true
      expect(options.key?(:inexistent)).to be false
    end
  end

  describe '#to_hash' do
    it 'returns the hash representation of the config' do
      expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
    end
  end

  describe '#dup' do
    it 'returns a deep copy' do
      new_options = options.dup
      expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
      expect(new_options.to_hash).to eq(options.to_hash)

      new_options['test'] = 1
      new_options['foo']['bar'] = 'zzz'

      expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
      expect(new_options.to_hash).to eq('test' => 1, 'foo' => { 'bar' => 'zzz' })
    end
  end

  describe '#merge' do
    it 'returns a new object with the options merged' do
      expect(options.merge(more: 'configs').to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'returns a new object with the duplicated options replaced' do
        expect(options.merge(foo: 'configs').to_hash).to eq('foo' => 'configs')
      end
    end
  end

  describe '#merge!' do
    it 'merges in place with the existing options' do
      options.merge!(more: 'configs') # rubocop: disable Performance/RedundantMerge

      expect(options.to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges in place with the duplicated options replaced' do
        options.merge!(foo: 'configs') # rubocop: disable Performance/RedundantMerge

        expect(options.to_hash).to eq('foo' => 'configs')
      end
    end
  end

  describe '#reverse_merge!' do
    it 'merges in place with the existing options' do
      options.reverse_merge!(more: 'configs')

      expect(options.to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges in place with the duplicated options not replaced' do
        options.reverse_merge!(foo: 'configs')

        expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
      end
    end
  end

  describe '#deep_merge' do
    it 'returns a new object with the options merged' do
      expect(options.deep_merge(foo: { more: 'configs' }).to_hash).to eq('foo' => {
        'bar' => 'baz',
        'more' => 'configs'
      })
    end

    context 'when the merge hash replaces existing configs' do
      it 'returns a new object with the duplicated options replaced' do
        expect(options.deep_merge(foo: { bar: 'configs' }).to_hash).to eq('foo' => {
          'bar' => 'configs'
        })
      end
    end
  end

  describe '#deep_merge!' do
    it 'merges in place with the existing options' do
      expect(options.deep_merge(foo: { more: 'configs' }).to_hash).to eq('foo' => {
        'bar' => 'baz',
        'more' => 'configs'
      })
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges in place with the duplicated options replaced' do
        expect(options.deep_merge(foo: { bar: 'configs' }).to_hash).to eq('foo' => {
          'bar' => 'configs'
        })
      end
    end
  end

  describe '#is_a?' do
    it 'returns false for anything different of Hash or Gitlab::Configs::Options' do
      expect(options.is_a?(described_class)).to be true
      expect(options.is_a?(Hash)).to be true
      expect(options.is_a?(String)).to be false
    end
  end

  describe '#symbolize_keys!' do
    it_behaves_like 'do not mutate', :symbolize_keys!
  end

  describe '#stringify_keys!' do
    it_behaves_like 'do not mutate', :stringify_keys!
  end

  describe '#method_missing' do
    context 'when method is an option' do
      it 'delegates methods to options keys' do
        expect(options.foo.bar).to eq('baz')
      end

      it 'uses methods to change options values' do
        expect { options.foo = 1 }
          .to change { options.foo }
          .to(1)
      end
    end

    context 'when method is not an option' do
      context 'when no callback is installed (default)' do
        it 'raises to prevent unintended hash method delegation' do
          exception = 'Calling a hash method on Gitlab::Configs::Options: `delete`'

          expect { options.foo.delete('bar') }.to raise_error(exception)
        end
      end

      context 'when a callback is installed' do
        let(:received_messages) { [] }

        before do
          Gitlab::Configs.on_mutation_warning = ->(message, extra) { received_messages << { message: message, extra: extra } }
        end

        after do
          Gitlab::Configs.on_mutation_warning = nil
        end

        it 'invokes the callback and delegates the method to the internal options hash' do
          expect { options.foo.delete('bar') }
            .to change { options.to_hash }
            .to({ 'foo' => {} })

          expect(received_messages.length).to eq(1)
          expect(received_messages.first[:message]).to eq(
            'Calling a hash method on Gitlab::Configs::Options: `delete`'
          )
          expect(received_messages.first[:extra]).to include(method: :delete)
          expect(received_messages.first[:extra][:caller]).to be_an(Array).and(be_present)
        end
      end
    end

    context 'when method is not an option and does not exist in hash' do
      it 'raises Gitlab::Configs::MissingConfig' do
        expect { options.anything }
          .to raise_error(
            ::Gitlab::Configs::MissingConfig,
            "option 'anything' not defined"
          )
      end
    end
  end
end
