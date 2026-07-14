# frozen_string_literal: true

require 'fast_spec_helper'
require_relative 'helpers/contract_source_helper'

RSpec.describe Provider::ContractSourceHelper, feature_category: :pipeline_composition do
  subject(:helper) { described_class }

  let(:pact_helper_path) { 'pact_helpers/project/pipelines/new/post_create_pipeline_helper.rb' }
  let(:split_pact_helper_path) { %w[pipelines new post_create_pipeline] }
  let(:provider_url_path) { 'POST%20create%20pipeline' }
  let(:consumer_url_path) { 'Pipelines%23new' }

  describe '#contract_location' do
    it 'raises an error when an invalid requester is given' do
      expect { helper.contract_location(requester: :foo, file_path: pact_helper_path) }
        .to raise_error(ArgumentError, 'requester must be :rake or :spec')
    end

    it 'raises an error when an invalid edition is given' do
      expect { helper.contract_location(requester: :spec, file_path: pact_helper_path, edition: :zz) }
        .to raise_error(ArgumentError, 'edition must be :ce or :ee')
    end

    context 'when the PACT_BROKER environment variable is not set' do
      it 'extracts the relevant path from the pact_helper path' do
        expect(helper).to receive(:local_contract_location).with(:rake, split_pact_helper_path, :ce)

        helper.contract_location(requester: :rake, file_path: pact_helper_path)
      end

      it 'does not construct the pact broker url' do
        expect(helper).not_to receive(:pact_broker_url)

        helper.contract_location(requester: :rake, file_path: pact_helper_path)
      end
    end

    context 'when the PACT_BROKER environment variable is set' do
      before do
        stub_env('PACT_BROKER', true)
      end

      it 'extracts the relevant path from the pact_helper path' do
        expect(helper).to receive(:pact_broker_url).with(split_pact_helper_path)

        helper.contract_location(requester: :spec, file_path: pact_helper_path)
      end

      it 'does not construct the local contract location' do
        expect(helper).not_to receive(:local_contract_location)

        helper.contract_location(requester: :spec, file_path: pact_helper_path)
      end
    end
  end

  describe '#pact_broker_url' do
    before do
      stub_env('QA_PACT_BROKER_HOST', 'http://localhost')
    end

    it 'returns the full url to the contract that the provider test is verifying' do
      contract_url_path =
        "http://localhost/pacts/provider/#{provider_url_path}/consumer/#{consumer_url_path}/latest"

      expect(helper.pact_broker_url(split_pact_helper_path)).to eq(contract_url_path)
    end
  end

  describe '#construct_provider_url_path' do
    it 'returns the provider url path' do
      expect(helper.construct_provider_url_path(split_pact_helper_path)).to eq(provider_url_path)
    end
  end

  describe '#construct_consumer_url_path' do
    it 'returns the consumer url path' do
      expect(helper.construct_consumer_url_path(split_pact_helper_path)).to eq(consumer_url_path)
    end
  end

  describe '#local_contract_location' do
    it 'returns the contract file path with the prefix path for a rake task' do
      rake_task_relative_path = '/spec/contracts/contracts/internal/project'

      rake_task_path = helper.local_contract_location(:rake, split_pact_helper_path, :ce)

      expect(rake_task_path).to include(rake_task_relative_path)
      expect(rake_task_path).not_to include('../')
    end

    it 'returns the contract file path with the prefix path for a spec' do
      spec_relative_path = '../contracts/internal/project'

      expect(helper.local_contract_location(:spec, split_pact_helper_path, :ce)).to include(spec_relative_path)
    end
  end

  describe '#construct_local_contract_path' do
    it 'returns the local contract path' do
      contract_path = '/pipelines/new/pipelines#new-post_create_pipeline.json'

      expect(helper.construct_local_contract_path(split_pact_helper_path)).to eq(contract_path)
    end
  end
end
