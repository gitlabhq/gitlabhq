# frozen_string_literal: true

require 'spec_helper'
require 'cells/mailroom/processor'

RSpec.describe Cells::Mailroom::Processor do
  let(:cell_router) { instance_double(Cells::Mailroom::CellRouter) }
  let(:forwarder) { instance_double(Cells::Mailroom::Forwarder) }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:raw) { "To: incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue@example.com\r\n\r\nbody" }

  subject(:processor) do
    described_class.new(
      wildcard_address: 'incoming+%{key}@example.com',
      gitlab_host: 'gitlab.example.com',
      route_unidentified_to_default_cell: route_unidentified_to_default_cell,
      cell_router: cell_router,
      forwarder: forwarder,
      logger: logger
    )
  end

  let(:route_unidentified_to_default_cell) { true }

  before do
    allow(cell_router).to receive(:default_cell_address).and_return(nil)
  end

  describe '#process' do
    it 'forwards to the cell resolved from the first matching target' do
      allow(cell_router).to receive(:address_for)
        .with(Gitlab::EmailHandler::Target.project_id(20))
        .and_return('cell-1.example.com:443')
      expect(cell_router).not_to receive(:default_cell_address)
      expect(forwarder).to receive(:forward).with(raw, 'cell-1.example.com:443').and_return(true)

      expect(processor.process(raw)).to be(true)
    end

    context 'when no candidate resolves to a cell' do
      before do
        allow(cell_router).to receive(:address_for).and_return(nil)
      end

      it 'routes to the default cell' do
        allow(cell_router).to receive(:default_cell_address).and_return('default-cell.example.com:443')
        expect(forwarder).to receive(:forward).with(raw, 'default-cell.example.com:443').and_return(true)

        expect(processor.process(raw)).to be(true)
      end

      it 'drops the email when no default cell is available' do
        allow(cell_router).to receive(:default_cell_address).and_return(nil)
        expect(forwarder).not_to receive(:forward)

        expect(processor.process(raw)).to be(false)
      end

      context 'when routing to the default cell is disabled' do
        let(:route_unidentified_to_default_cell) { false }

        it 'drops the email without consulting the default cell' do
          expect(cell_router).not_to receive(:default_cell_address)
          expect(forwarder).not_to receive(:forward)

          expect(processor.process(raw)).to be(false)
        end
      end
    end

    it 'routes to the default cell when there are no candidates' do
      raw = "To: not-an-email\r\n\r\nbody"
      allow(cell_router).to receive(:default_cell_address).and_return('default-cell.example.com:443')
      expect(cell_router).not_to receive(:address_for)
      expect(forwarder).to receive(:forward).with(raw, 'default-cell.example.com:443').and_return(true)

      expect(processor.process(raw)).to be(true)
    end

    it 'falls through a candidate that parses but does not resolve to a cell' do
      # The To address is a well-formed custom email that the Topology Service
      # does not recognise; routing should fall through to the project id in the
      # Delivered-To wildcard key.
      raw = <<~EMAIL
        To: support@acme.com
        Delivered-To: incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue@example.com

        body
      EMAIL
      allow(cell_router).to receive(:address_for).and_return(nil)
      allow(cell_router).to receive(:address_for)
        .with(Gitlab::EmailHandler::Target.project_id(20))
        .and_return('cell-1.example.com:443')
      expect(forwarder).to receive(:forward).with(raw, 'cell-1.example.com:443').and_return(true)

      expect(processor.process(raw)).to be(true)
    end

    it 'routes using the references message-id fallback' do
      raw = <<~EMAIL
        To: jake@example.com
        References: <other@example.com> <reply-rs-0000000000000000000000abc-rs@gitlab.example.com>

        body
      EMAIL
      target = Gitlab::EmailHandler::Target.namespace_id(1000)
      allow(cell_router).to receive(:address_for).and_return(nil)
      allow(cell_router).to receive(:address_for).with(target).and_return('cell-1.example.com:443')
      expect(forwarder).to receive(:forward).with(raw, 'cell-1.example.com:443').and_return(true)

      expect(processor.process(raw)).to be(true)
    end

    it 'returns false and does not raise when processing fails' do
      allow(cell_router).to receive(:address_for).and_raise(StandardError, 'boom')

      expect(processor.process(raw)).to be(false)
      expect(logger).to have_received(:warn)
        .with(hash_including(Labkit::Fields::LOG_MESSAGE => 'Failed to process email'))
    end
  end
end
