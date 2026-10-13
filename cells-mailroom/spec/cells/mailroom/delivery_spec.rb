# frozen_string_literal: true

require 'spec_helper'
require 'cells/mailroom/delivery'

RSpec.describe Cells::Mailroom::Delivery do
  let(:mailbox) do
    double( # rubocop:disable RSpec/VerifiedDoubles -- MailRoom::Mailbox is not loaded in this unit spec
      delivery_options: { mailbox_type: 'incoming_email', wildcard_address: 'incoming+%{key}@example.com' },
      logger: instance_double(Logger, info: nil, warn: nil)
    )
  end

  subject(:delivery) { described_class.new(described_class::Options.new(mailbox)) }

  let(:processor) { instance_double(Cells::Mailroom::Processor) }

  before do
    allow(delivery).to receive(:processor).and_return(processor)
  end

  describe '#deliver' do
    # mail_room removes a message from the mailbox only when the handler returns
    # truthy, so the Processor result must be propagated rather than swallowed.
    it 'returns true when the processor reports success' do
      allow(processor).to receive(:process).with('raw').and_return(true)

      expect(delivery.deliver('raw')).to be(true)
    end

    it 'returns false when the processor reports failure, so the message is retried' do
      allow(processor).to receive(:process).with('raw').and_return(false)

      expect(delivery.deliver('raw')).to be(false)
    end
  end
end
