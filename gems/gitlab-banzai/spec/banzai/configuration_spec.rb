# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Configuration do
  subject(:configuration) { described_class.new }

  it 'returns a plain value as given' do
    configuration.timeout_disabled = true

    expect(configuration.timeout_disabled).to be true
  end

  it 'resolves a callable on every read' do
    reads = 0
    configuration.timeout_disabled = -> { reads += 1 }

    configuration.timeout_disabled
    configuration.timeout_disabled

    expect(reads).to eq(2)
  end

  it 'resolves a false callable rather than treating the input as unset' do
    configuration.timeout_disabled = -> { false }

    expect(configuration.timeout_disabled).to be false
  end

  it 'raises a configuration error naming the input when it was never set' do
    expect { configuration.timeout_disabled }.to raise_error(
      Banzai::MissingConfigurationError,
      /`Banzai` input `timeout_disabled` is not configured.*Banzai\.configure.*config\.timeout_disabled/m
    )
  end

  context 'with a port that takes arguments' do
    # No real port takes an argument yet, so this stand-in declares one the
    # same way `url_builder` will.
    subject(:configuration) do
      Class.new(described_class) do
        attr_writer :url_builder

        def url_builder(object)
          resolve(:url_builder, @url_builder, object)
        end
      end.new
    end

    it 'passes the reader arguments to a callable' do
      configuration.url_builder = ->(object) { "https://gitlab.example.com/#{object}" }

      expect(configuration.url_builder('issues/1')).to eq('https://gitlab.example.com/issues/1')
    end

    it 'returns a plain value as given' do
      configuration.url_builder = 'https://gitlab.example.com'

      expect(configuration.url_builder('issues/1')).to eq('https://gitlab.example.com')
    end
  end
end
