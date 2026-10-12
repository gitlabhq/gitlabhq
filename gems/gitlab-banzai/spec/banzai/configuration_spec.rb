# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Configuration do
  # No port is declared yet, so `resolve` is exercised through a stand-in that
  # declares one the same way a real port will.
  let(:configuration_class) do
    Class.new(described_class) do
      attr_writer :url_builder

      def url_builder
        resolve(:url_builder, @url_builder)
      end
    end
  end

  subject(:configuration) { configuration_class.new }

  it 'returns a plain value as given' do
    configuration.url_builder = 'https://gitlab.example.com'

    expect(configuration.url_builder).to eq('https://gitlab.example.com')
  end

  it 'resolves a callable on every read' do
    reads = 0
    configuration.url_builder = -> { reads += 1 }

    configuration.url_builder
    configuration.url_builder

    expect(reads).to eq(2)
  end

  it 'raises a configuration error naming the input when it was never set' do
    expect { configuration.url_builder }.to raise_error(
      Banzai::MissingConfigurationError,
      /`Banzai` input `url_builder` is not configured.*Banzai\.configure.*config\.url_builder/m
    )
  end
end
