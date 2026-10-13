# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::Mailroom::CellRouter do
  let(:stub) { instance_double(Gitlab::Cells::TopologyService::ClassifyService::Stub) }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }

  subject(:router) { described_class.new(stub: stub, logger: logger) }

  let(:proxy) { Gitlab::Cells::TopologyService::ProxyInfo.new(address: 'cell-1.example.com:443') }
  let(:response) do
    Gitlab::Cells::TopologyService::ClassifyResponse.new(
      action: Gitlab::Cells::TopologyService::ClassifyAction::PROXY,
      proxy: proxy
    )
  end

  describe '#address_for' do
    it 'returns nil for a nil target without calling the service' do
      expect(stub).not_to receive(:classify)

      expect(router.address_for(nil)).to be_nil
    end

    it 'returns the cell address for a target that resolves' do
      expect(stub).to receive(:classify).and_return(response)

      expect(router.address_for(Gitlab::EmailHandler::Target.project_id(54))).to eq('cell-1.example.com:443')
    end

    it 'returns nil when the target is not found' do
      expect(stub).to receive(:classify).and_raise(GRPC::NotFound.new('claim not found'))

      target = Gitlab::EmailHandler::Target.service_desk_custom_email('unknown@acme.com')
      expect(router.address_for(target)).to be_nil
    end

    it 'returns nil on other Topology Service errors' do
      expect(stub).to receive(:classify).and_raise(GRPC::Unavailable.new('connection failed'))

      expect(router.address_for(Gitlab::EmailHandler::Target.project_id(54))).to be_nil
    end

    describe 'address validation' do
      # An address we cannot turn into a URL authority is treated as
      # unresolved, so the caller falls back to the default cell.
      [
        ['an address with a path', 'cell-1.example.com/api'],
        ['a bracketed IPv6 address', '[::1]:443'],
        ['a bare IPv6 address', '::1'],
        ['an address with no host', ':443'],
        ['an empty address', '']
      ].each do |description, address|
        it "returns nil for #{description}" do
          proxy = Gitlab::Cells::TopologyService::ProxyInfo.new(address: address)
          allow(stub).to receive(:classify).and_return(
            Gitlab::Cells::TopologyService::ClassifyResponse.new(
              action: Gitlab::Cells::TopologyService::ClassifyAction::PROXY, proxy: proxy
            )
          )

          expect(router.address_for(Gitlab::EmailHandler::Target.project_id(54))).to be_nil
        end
      end

      it 'accepts a host without a port' do
        proxy = Gitlab::Cells::TopologyService::ProxyInfo.new(address: 'cell-1.example.com')
        allow(stub).to receive(:classify).and_return(
          Gitlab::Cells::TopologyService::ClassifyResponse.new(
            action: Gitlab::Cells::TopologyService::ClassifyAction::PROXY, proxy: proxy
          )
        )

        expect(router.address_for(Gitlab::EmailHandler::Target.project_id(54))).to eq('cell-1.example.com')
      end

      it 'logs the unusable address' do
        proxy = Gitlab::Cells::TopologyService::ProxyInfo.new(address: '[::1]:443')
        allow(stub).to receive(:classify).and_return(
          Gitlab::Cells::TopologyService::ClassifyResponse.new(
            action: Gitlab::Cells::TopologyService::ClassifyAction::PROXY, proxy: proxy
          )
        )

        expect(logger).to receive(:warn).with(hash_including(Labkit::Fields::TCP_ADDRESS => '[::1]:443'))

        router.address_for(Gitlab::EmailHandler::Target.project_id(54))
      end
    end

    describe 'target translation' do
      {
        'project id' => [Gitlab::EmailHandler::Target.project_id(54), :project_id, 54],
        'namespace id' => [Gitlab::EmailHandler::Target.namespace_id(7), :namespace_id, 7],
        'route' => [Gitlab::EmailHandler::Target.route('gitlab-org/gitlab'), :route, 'gitlab-org'],
        'custom email' => [
          Gitlab::EmailHandler::Target.service_desk_custom_email('support@acme.com'),
          :service_desk_custom_email,
          'support@acme.com'
        ],
        'project key address slug' => [
          Gitlab::EmailHandler::Target.service_desk_project_key_address_slug('gitlab-org-gitlab-ce-mykey_123'),
          :service_desk_project_key_address_slug,
          'gitlab-org-gitlab-ce-mykey_123'
        ]
      }.each do |name, (target, field, value)|
        it "sends a #{name} claim to Classify" do
          expect(stub).to receive(:classify) do |request|
            expect(request.claims.first.public_send(field)).to eq(value)
            response
          end

          router.address_for(target)
        end
      end
    end

    it 'raises for an unsupported target kind' do
      bogus = Gitlab::EmailHandler::Target.new(kind: :unknown, value: 'x')

      expect { router.address_for(bogus) }.to raise_error(described_class::UnsupportedTargetError)
    end
  end

  describe '#default_cell_address' do
    it 'classifies with the FIRST_CELL type and returns the cell address' do
      expect(stub).to receive(:classify) do |request|
        expect(request.type).to eq(:FIRST_CELL)
        response
      end

      expect(router.default_cell_address).to eq('cell-1.example.com:443')
    end

    it 'returns nil when no default cell is found' do
      expect(stub).to receive(:classify).and_raise(GRPC::NotFound.new('no first cell'))

      expect(router.default_cell_address).to be_nil
    end

    it 'returns nil on other Topology Service errors' do
      expect(stub).to receive(:classify).and_raise(GRPC::Unavailable.new('connection failed'))

      expect(router.default_cell_address).to be_nil
    end
  end
end
