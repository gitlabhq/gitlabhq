# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ConfigResolver do
  include GraphqlHelpers

  describe '#resolve' do
    before do
      yaml_processor_double = instance_double(::Gitlab::Ci::YamlProcessor)
      allow(yaml_processor_double).to receive(:execute).and_return(fake_result)

      allow(::Gitlab::Ci::YamlProcessor).to receive(:new).and_return(yaml_processor_double)
    end

    context 'with a valid .gitlab-ci.yml' do
      let(:fake_result) do
        ::Gitlab::Ci::YamlProcessor::Result.new(
          ci_config: ::Gitlab::Ci::Config.new(content),
          errors: [],
          warnings: []
        )
      end

      let_it_be(:content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
      end

      it 'lints the ci config file' do
        response = resolve(described_class, args: { content: content }, ctx: {})

        expect(response[:status]).to eq(:valid)
        expect(response[:errors]).to be_empty
      end
    end

    context 'with an invalid .gitlab-ci.yml' do
      let(:content) { 'invalid' }

      let(:fake_result) do
        Gitlab::Ci::YamlProcessor::Result.new(
          ci_config: nil,
          errors: ['Invalid configuration format'],
          warnings: []
        )
      end

      it 'responds with errors about invalid syntax' do
        response = resolve(described_class, args: { content: content }, ctx: {})

        expect(response[:status]).to eq(:invalid)
        expect(response[:errors]).to eq(['Invalid configuration format'])
      end
    end
  end
end
