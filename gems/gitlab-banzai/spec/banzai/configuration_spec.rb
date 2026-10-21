# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Configuration do
  # No port is declared yet, so `resolve` is exercised through a stand-in that
  # declares one the same way a real port will.
  let(:configuration_class) do
    Class.new(described_class) do
      attr_writer :instance_url, :url_builder

      def instance_url
        resolve(:instance_url, @instance_url)
      end

      def url_builder(object)
        resolve(:url_builder, @url_builder, object)
      end
    end
  end

  subject(:configuration) { configuration_class.new }

  it 'returns a plain value as given' do
    configuration.instance_url = 'https://gitlab.example.com'

    expect(configuration.instance_url).to eq('https://gitlab.example.com')
  end

  it 'resolves a callable on every read' do
    reads = 0
    configuration.instance_url = -> { reads += 1 }

    configuration.instance_url
    configuration.instance_url

    expect(reads).to eq(2)
  end

  it 'passes the reader arguments to a callable' do
    configuration.url_builder = ->(object) { "https://gitlab.example.com/#{object}" }

    expect(configuration.url_builder('issues/1')).to eq('https://gitlab.example.com/issues/1')
  end

  it 'returns a plain value as given when the reader takes arguments' do
    configuration.url_builder = 'https://gitlab.example.com'

    expect(configuration.url_builder('issues/1')).to eq('https://gitlab.example.com')
  end

  it 'raises a configuration error naming the input when it was never set' do
    expect { configuration.url_builder('issues/1') }.to raise_error(
      Banzai::MissingConfigurationError,
      /`Banzai` input `url_builder` is not configured.*Banzai\.configure.*config\.url_builder/m
    )
  end
end
